# frozen_string_literal: true

# Schema implementation - reopen Prosereflect::Schema class to add instance methods
module Prosereflect
  class Schema
    # Alias ValidationError for backwards compatibility
    ValidationError = Prosereflect::SchemaErrors::ValidationError

    attr_reader :spec, :nodes, :marks

    def initialize(nodes_spec:, marks_spec: {}, top_node: nil)
      @spec = SchemaSpec.from_hashes(nodes_spec: nodes_spec,
                                     marks_spec: marks_spec, top_node: top_node)
      @nodes = {} # name -> NodeType
      @marks = {} # name -> MarkType

      # Build NodeTypes
      @spec.nodes.each do |name, node_spec|
        @nodes[name] = NodeType.from_spec(name, self, node_spec)
      end

      # Build MarkTypes
      rank = 0
      @spec.marks.each do |name, mark_spec|
        @marks[name] = MarkType.from_spec(name, rank, self, mark_spec)
        rank += 1
      end

      # Validate schema
      validate_schema

      # Build content expressions
      build_content_matches

      # Build mark sets
      build_mark_sets

      # Build mark exclusions
      build_mark_exclusions

      @top_node_type = @nodes[@spec.top_node]
    end

    def top_node_type
      @top_node_type
    end

    def node_type(name)
      @nodes[name] || raise(::Prosereflect::SchemaErrors::ValidationError,
                            "Unknown node type: #{name}")
    end

    def mark_type(name)
      @marks[name] || raise(::Prosereflect::SchemaErrors::ValidationError,
                            "Unknown mark type: #{name}")
    end

    # Create a node
    def node(type, attrs = nil, content = nil, marks = nil)
      type_obj = type.is_a?(String) ? node_type(type) : type
      unless type_obj.is_a?(NodeType)
        raise ::Prosereflect::SchemaErrors::Error,
              "Invalid node type: #{type}"
      end
      if type_obj.schema != self
        raise ::Prosereflect::SchemaErrors::Error,
              "Node type from different schema used (#{type_obj.name})"
      end

      type_obj.create_checked(attrs, content, marks)
    end

    # Create a text node
    def text(text, marks = nil)
      type = node_type("text")
      TextNode.new(type: type, attrs: {}, text: text, marks: marks || [])
    end

    # Create a mark
    def mark(type, attrs = nil)
      type_obj = type.is_a?(String) ? mark_type(type) : type
      type_obj.create(attrs)
    end

    # Deserialize node from JSON
    def node_from_json(json_data)
      Node.from_json(self, json_data)
    end

    # Deserialize mark from JSON
    def mark_from_json(json_data)
      type = mark_type(json_data["type"])
      attrs = json_data["attrs"] || {}
      type.create(attrs)
    end

    private

    def validate_schema
      unless @nodes.key?(@spec.top_node)
        raise ::Prosereflect::SchemaErrors::ValidationError,
              "Schema is missing its top node type #{@spec.top_node}"
      end

      unless @nodes.key?("text")
        raise ::Prosereflect::SchemaErrors::ValidationError,
              "every schema needs a 'text' type"
      end

      if @nodes["text"].attrs && !@nodes["text"].attrs.empty?
        raise ::Prosereflect::SchemaErrors::ValidationError,
              "the text node type should not have attributes"
      end

      @nodes.each_key do |name|
        if @marks.key?(name)
          raise ::Prosereflect::SchemaErrors::ValidationError,
                "#{name} can not be both a node and a mark"
        end
      end
    end

    def build_content_matches
      @nodes.each_value do |node_type|
        content_expr = node_type.content_expression
        next unless content_expr

        node_type.instance_variable_set(
          :@content_match,
          ContentMatch.parse(content_expr, @nodes),
        )
      end
    end

    def build_mark_sets
      @nodes.each_value do |node_type|
        mark_expr = if node_type.spec.respond_to?(:[])
                      node_type.spec[:marks] || node_type.spec["marks"]
                    elsif node_type.spec.respond_to?(:marks)
                      node_type.spec.marks
                    end

        node_type.mark_set = if mark_expr == "_"
          nil # All marks allowed
        elsif mark_expr.is_a?(String) && !mark_expr.empty?
          gather_marks(mark_expr.split)
        elsif mark_expr == "" || !node_type.content_match.inline_content?
          []
        end
      end
    end

    def gather_marks(names)
      result = []
      names.each do |name|
        if @marks.key?(name)
          result << @marks[name]
        else
          # Check groups
          @marks.each_value do |mark|
            group_str = mark.spec.respond_to?(:group) ? mark.spec.group : nil

            if group_str && group_str.to_s.split.include?(name)
              result << mark
            end
          end
        end
      end
      result
    end

    def build_mark_exclusions
      @marks.each_value do |mark|
        excl = if mark.spec.respond_to?(:[])
                 mark.spec[:excludes] || mark.spec["excludes"]
               elsif mark.spec.respond_to?(:excludes)
                 mark.spec.excludes
               end

        mark.excluded = if excl.nil?
                          [mark]
                        elsif excl == ""
                          []
                        else
                          gather_marks(excl.split)
                        end
      end
    end
  end
end
