# frozen_string_literal: true

module Prosereflect
  class Schema
    class NodeType
      attr_reader :name, :attrs, :content_match, :groups, :schema, :spec,
                  :content_expression
      attr_accessor :mark_set

      def initialize(name:, attrs: {}, content_expression: nil, groups: [],
                     schema: nil, spec: nil, inline: false, atom: false)
        @name = name
        @attrs = attrs
        @groups = groups
        @schema = schema
        @spec = spec
        @inline = inline
        @atom = atom
        @mark_set = nil
        @content_expression = content_expression

        # Content match will be built later by Schema#build_content_matches
        # to avoid circular dependency issues during node type construction
        @content_match = ContentMatch.empty
      end

      def self.from_spec(name, schema, spec)
        attrs = {}
        if spec.respond_to?(:attrs)
          spec_attrs = spec.attrs
          attrs = if spec_attrs.is_a?(Hash)
                    # New format: {"attr_name" => {default: value}} or attr_name as key
                    spec_attrs.each_with_object({}) do |(attr_name, attr_spec), hash|
                      if attr_spec.respond_to?(:name)
                        hash[attr_name] =
                          Attribute.new(name: attr_spec.name,
                                        default: attr_spec.default)
                      else
                        # attr_spec is a Hash with :default, :name, etc as keys
                        attr_name = attr_spec[:name] || attr_spec["name"] || attr_name
                        default = attr_spec[:default] || attr_spec["default"]
                        hash[attr_name] =
                          Attribute.new(name: attr_name, default: default)
                      end
                    end
                  else
                    # Old format: values are attribute objects with .name and .default
                    spec_attrs.transform_values do |a|
                      Attribute.new(name: a.name, default: a.default)
                    end
                  end
        elsif spec.is_a?(Hash)
          spec_attrs = spec[:attrs] || spec["attrs"] || {}
          attrs = spec_attrs.transform_values do |v|
            Attribute.new(
              name: v[:name] || v["name"] || v.keys.first,
              default: v[:default] || v["default"],
            )
          end
        end

        content_expr = spec.respond_to?(:content) ? spec.content : (spec[:content] || spec["content"])
        groups = spec.respond_to?(:groups) ? spec.groups : parse_groups(spec)
        inline = spec.respond_to?(:inline) ? spec.inline : (spec[:inline] || spec["inline"] || false)
        atom = spec.respond_to?(:atom) ? spec.atom : (spec[:atom] || spec["atom"] || false)

        new(
          name: name,
          attrs: attrs,
          content_expression: content_expr,
          groups: groups,
          schema: schema,
          spec: spec,
          inline: inline,
          atom: atom,
        )
      end

      def self.parse_groups(spec)
        group_str = spec[:group] || spec["group"]
        return [] unless group_str

        group_str.is_a?(Array) ? group_str : group_str.to_s.split
      end

      def is_block?
        !@inline && @name != "text"
      end

      def is_inline?
        !is_block?
      end

      alias inline? is_inline?

      def text?
        @name == "text"
      end

      def is_leaf?
        @content_match == ContentMatch.empty || @content_match.edge_count.zero?
      end

      def is_atom?
        is_leaf? || @atom
      end

      def is_textblock?
        is_block? && @content_match.inline_content?
      end

      def in_group?(group_name)
        return true if group_name == "inline" && text?
        return true if group_name == "block" && is_block?

        @groups.include?(group_name)
      end

      def has_required_attrs?
        @attrs.values.any?(&:required?)
      end

      def default_attrs
        defaults = {}
        @attrs.each do |name, attr_def|
          return nil unless attr_def.has_default?

          defaults[name] = attr_def.default
        end
        defaults.empty? ? nil : defaults
      end

      def compute_attrs(attrs)
        return default_attrs if attrs.nil?

        built = {}
        @attrs.each do |name, attr_def|
          if attrs.key?(name)
            built[name] = attrs[name]
          elsif attr_def.has_default?
            built[name] = attr_def.default
          else
            raise Prosereflect::SchemaErrors::ValidationError,
                  "No value supplied for attribute #{name} on node #{@name}"
          end
        end
        built
      end

      # Create a node with validation
      def create(attrs = nil, content = nil, marks = [])
        if text?
          raise Prosereflect::SchemaErrors::Error,
                "NodeType.create cannot construct text nodes"
        end

        content_fragment = case content
                           when Fragment then content
                           when nil then Fragment.empty
                           when Array then Fragment.new(content)
                           when Node then Fragment.new([content])
                           end

        attrs = compute_attrs(attrs)
        Node.new(type: self, attrs: attrs, content: content_fragment,
                 marks: marks)
      end

      # Create a node with content validation
      def create_checked(attrs = nil, content = nil, marks = [])
        content_fragment = case content
                           when Fragment then content
                           when nil then Fragment.empty
                           when Array then Fragment.new(content)
                           when Node then Fragment.new([content])
                           end

        check_content(content_fragment)
        attrs = compute_attrs(attrs)
        Node.new(type: self, attrs: attrs, content: content_fragment,
                 marks: marks)
      end

      # Create and fill a node with default content
      def create_and_fill(attrs = nil, content = nil, marks = [])
        attrs = compute_attrs(attrs)
        content_fragment = Fragment.from(content)

        if content_fragment.size.positive?
          before = @content_match.fill_before(after: content_fragment,
                                              to_end: false)
          return nil unless before

          content_fragment = before.append(content_fragment)
        end

        matched = @content_match.match_fragment(content_fragment)
        return nil unless matched

        after = matched.fill_before(after: Fragment.empty, to_end: true)
        return nil unless after

        full_content = content_fragment.append(after)
        Node.new(type: self, attrs: attrs, content: full_content, marks: marks)
      end

      def valid_content?(fragment)
        result = @content_match.match_fragment(fragment)
        return false unless result&.valid_end

        fragment.content.each do |child|
          return false unless allows_marks?(child.marks)
        end
        true
      end

      def check_content(fragment)
        return if valid_content?(fragment)

        raise Prosereflect::SchemaErrors::ValidationError,
              "Invalid content for node #{@name}: #{fragment.to_s[0, 50]}"
      end

      def check_attrs(attrs)
        attrs ||= {}
        attrs.each_key do |attr_name|
          unless @attrs.key?(attr_name)
            raise Prosereflect::SchemaErrors::ValidationError,
                  "Unsupported attribute #{attr_name} for node #{@name}"
          end
        end

        @attrs.each do |name, attr_def|
          attr_def.validate_value(attrs[name]) if attrs.key?(name)
        end
      end

      def allows_mark_type?(mark_type)
        @mark_set.nil? || @mark_set.include?(mark_type)
      end

      def allows_marks?(marks)
        return true if @mark_set.nil?

        marks.all? { |mark| allows_mark_type?(mark.type) }
      end

      def allowed_marks(marks)
        return marks if @mark_set.nil?

        result = marks.dup
        filtered = false

        marks.each_with_index do |mark, i|
          unless allows_mark_type?(mark.type)
            result = marks[0...i].dup
            filtered = true
            break
          end
        end

        filtered ? result : marks
      end

      def compatible_content?(other)
        self == other || @content_match.compatible?(other.content_match)
      end

      def to_s
        "<NodeType #{@name}>"
      end
    end
  end
end
