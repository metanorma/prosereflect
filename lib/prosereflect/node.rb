# frozen_string_literal: true

module Prosereflect
  class Node < Lutaml::Model::Serializable
    PM_TYPE = "node"

    attribute :type, :string
    attribute :attrs, :hash
    attribute :marks, Mark::Base, polymorphic: true, collection: true
    attribute :content, Node, polymorphic: true, collection: true

    key_value do
      map "type", to: :type, render_default: true
      map "attrs", to: :attrs
      map "marks", to: :marks
      map "content", to: :content
    end

    def initialize(data = nil, attrs = nil)
      if data.is_a?(String)
        super(type: data, attrs: attrs, content: [])
      elsif data.is_a?(Hash)
        # Handle marks in a special way to preserve expected behavior in tests
        if data[:marks] || data["marks"]
          marks_data = data[:marks] || data["marks"]
          data = data.dup
          data.delete("marks")
          data.delete(:marks)
          super(data)
          self.marks = marks_data
        else
          # Handle attrs properly
          if data[:attrs] || data["attrs"]
            data = data.dup
            data[:attrs] = process_attrs_data(data[:attrs] || data["attrs"])
          end
          super(data)
        end
      else
        super()
      end
    end

    def process_attrs_data(attrs_data)
      if attrs_data.is_a?(Hash)
        attrs_data.transform_keys(&:to_s)
      else
        attrs_data
      end
    end

    def self.create(type = nil, attrs = nil)
      new(type || self::PM_TYPE, attrs)
    rescue NameError
      new(type || "node", attrs)
    end

    # Convert to hash for serialization
    def to_h
      result = { "type" => type }

      if attrs && !attrs.empty?
        if attrs.is_a?(Hash)
          result["attrs"] = process_node_attributes(attrs, type)
        elsif attrs.is_a?(Array) && attrs.all? do |attr|
          attr.respond_to?(:to_h)
        end
          # Convert array of attribute objects to a hash
          attrs_array = attrs.map do |attr|
            attr.is_a?(Prosereflect::Attribute::Base) ? attr.to_h : attr
          end
          result["attrs"] = attrs_array unless attrs_array.empty?
        end
      end

      if marks && !marks.empty?
        result["marks"] = marks.map do |mark|
          if mark.is_a?(Hash)
            mark
          elsif mark.respond_to?(:to_h)
            mark.to_h
          elsif mark.respond_to?(:type)
            { "type" => mark.type.to_s }
          else
            raise ArgumentError, "Invalid mark type: #{mark.class}"
          end
        end
      end

      if content && !content.empty?
        result["content"] = if content.is_a?(Array)
                              content.map do |item|
                                item.respond_to?(:to_h) ? item.to_h : item
                              end
                            else
                              [content]
                            end
      end

      result
    end

    alias to_hash to_h

    def marks
      return nil if @marks.nil?
      return [] if @marks.empty?

      @marks.map do |mark|
        if mark.is_a?(Hash)
          mark
        elsif mark.respond_to?(:to_h)
          mark.to_h
        elsif mark.respond_to?(:type)
          { "type" => mark.type.to_s }
        else
          raise ArgumentError, "Invalid mark type: #{mark.class}"
        end
      end
    end

    def raw_marks
      @marks
    end

    def marks=(value)
      if value.nil?
        @marks = nil
      elsif value.is_a?(Array) && value.empty?
        @marks = []
      elsif value.is_a?(Array)
        @marks = value.map do |v|
          if v.is_a?(Hash)
            type = v["type"] || v[:type]
            attrs = v["attrs"] || v[:attrs]
            begin
              mark_class = Prosereflect::Mark.const_get(type.to_s.capitalize)
              mark_class.new(attrs: attrs)
            rescue NameError
              Mark::Base.new(type: type, attrs: attrs)
            end
          elsif v.is_a?(Mark::Base)
            v
          elsif v.respond_to?(:type)
            begin
              mark_class = Prosereflect::Mark.const_get(v.type.to_s.capitalize)
              mark_class.new(attrs: v.attrs)
            rescue NameError
              Mark::Base.new(type: v.type, attrs: v.attrs)
            end
          else
            raise ArgumentError, "Invalid mark type: #{v.class}"
          end
        end
      else
        super
      end
    end

    def parse_content(content_data)
      return [] unless content_data

      content_data.map { |item| Parser.parse(item) }
    end

    # Add a child node to this node's content
    def add_child(node)
      self.content ||= []
      content << node
      node
    end

    def find_first(node_type)
      return self if type == node_type

      return nil unless content

      content.each do |child|
        result = child.find_first(node_type)
        return result if result
      end
      nil
    end

    def find_all(node_type)
      results = []
      results << self if type == node_type

      content&.each do |child|
        child_results = child.find_all(node_type)
        results.concat(child_results) if child_results
      end

      results
    end

    def find_children(node_type)
      return [] unless content

      content.grep(node_type)
    end

    def text_content
      return "" unless content

      content.map(&:text_content).join
    end

    # Size of this node in the document tree.
    # For non-text nodes: 1 (opening token) + sum of children's node_size.
    # For text nodes: overridden to text.length + 1.
    def node_size
      size = 1
      content&.each { |child| size += child.node_size }
      size
    end

    # Whether this node represents a text node.
    # Overridden to true in Text class.
    def text?
      false
    end

    # Return a copy of this node with content restricted to the given range.
    # Positions are relative to the start of this node's content.
    def cut(from = 0, to = nil)
      to ||= node_size
      return self if from.zero? && to == node_size

      if text?
        # Text nodes override this
        self
      else
        copy(cut_content(from, to))
      end
    end

    # Iterate over all nodes between two positions in this node.
    # Accepts a block or a callable as the third positional argument.
    def nodes_between(from, to, callback = nil, node_start = 0, &block)
      cb = callback || block
      return unless cb && to > from && content

      pos = 0
      content.each_with_index do |child, i|
        break if pos >= to

        child_end = pos + child.node_size
        next unless child_end > from

        child_start = node_start + pos + 1
        if cb.call(child, child_start, i) != false && child.content && child.content.any?
          child.nodes_between(
            [0, from - pos - 1].max,
            [child.content ? child.content.size : 0, to - pos - 1].min,
            cb,
            child_start,
          )
        end

        pos = child_end
      end
    end

    # Iterate over all descendant nodes.
    def descendants(&block)
      nodes_between(0, node_size - 1, &block)
    end

    # Check structural equality with another node.
    def eq?(other)
      return false unless other.is_a?(Node)

      type == other.type && to_h == other.to_h
    end

    # Create a copy of this node with different content.
    def copy(new_content = nil)
      new_node = self.class.new(type: type, attrs: attrs, marks: raw_marks)
      case new_content
      when nil
        # no content
      when Array
        new_node.content = new_content
      when Fragment
        new_node.content = new_content.to_a
      else
        new_node.content = [new_content]
      end
      new_node
    end

    # Ensures YAML serialization outputs plain data instead of a Ruby object
    def to_yaml(*args)
      to_h.to_yaml(*args)
    end

    # Resolve a document position to a ResolvedPos
    def resolve(pos)
      path = []
      build_path_for_pos(pos, path)
      depth = [(path.length / 3) - 1, 0].max
      ResolvedPos.new(pos, path, depth)
    end

    # Get the node at a given depth in the path
    def node(depth)
      @path[depth * 2]
    end

    private

    def cut_content(from, to)
      return [] unless content

      result = []
      pos = 0
      content.each do |child|
        child_end = pos + child.node_size
        if pos >= from && child_end <= to
          result << child
        elsif pos < to && child_end > from
          result << child.cut([0, from - pos - 1].max, child.node_size - [0, child_end - to].max)
        end
        pos = child_end
        break if pos >= to
      end
      result
    end

    def build_path_for_pos(pos, path, index = 0, start_offset = 0)
      path << self << index << start_offset
      return if pos.zero?

      traverse_children_for_resolve(pos, path)
    end

    def traverse_children_for_resolve(pos, path)
      return unless content

      content_offset = 1
      child_index = 0

      content.each do |child|
        child_end = content_offset + child.node_size
        if pos < child_end
          child.send(:build_path_for_pos, pos - content_offset, path, child_index, content_offset)
          return
        end

        content_offset = child_end
        child_index += 1
      end
    end

    def process_node_attributes(attrs, _node_type)
      if attrs["attrs"].is_a?(Hash)
        attrs["attrs"]
      else
        attrs
      end
    end
  end
end
