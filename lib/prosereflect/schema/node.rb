# frozen_string_literal: true

module Prosereflect
  class Schema
    # Lightweight Node class for schema validation
    # This wraps the existing prosereflect Node and provides schema-aware methods
    class Node
      attr_reader :type, :attrs, :content, :marks

      def initialize(type:, attrs: {}, content: nil, marks: [])
        @type = type
        @attrs = attrs || {}
        @content = if content.is_a?(Fragment)
                     content
                   else
                     (content ? Fragment.new(content) : Fragment.empty)
                   end
        @marks = if marks.is_a?(Array)
                   marks
                 else
                   (marks ? [marks] : [])
                 end
      end

      def node_size
        size = 1 # Every node has at least size 1
        @content.content.each do |child|
          size += child.node_size
        end
        size
      end

      def text?
        @type.text?
      end

      def is_text
        text?
      end

      def is_block
        @type.is_block?
      end

      def is_inline
        @type.is_inline?
      end

      def is_leaf
        @type.is_leaf?
      end

      def is_atom
        @type.is_atom?
      end

      def same_markup?(other)
        return false unless @type == other.type && @marks.length == other.marks.length

        @marks.zip(other.marks).all? do |m1, m2|
          m1.type == m2.type && m1.attrs == m2.attrs
        end
      end

      def with_text(new_text)
        TextNode.new(type: @type, attrs: @attrs, text: new_text, marks: @marks)
      end

      def cut(from = 0, to = nil)
        to ||= node_size
        return self if from.zero? && to == node_size

        if text?
          # For text nodes, cut by character offset
          TextNode.new(
            type: @type,
            attrs: @attrs,
            text: @attrs[:text][from...to],
            marks: @marks,
          )
        else
          # For non-text nodes, cut content
          new_content = @content.cut(from - 1, to - 1)
          Node.new(type: @type, attrs: @attrs, content: new_content,
                   marks: @marks)
        end
      end

      def nodes_between(from, to, f, node_start = 0)
        return unless to > from

        if text?
          f.call(self, node_start)
          return
        end

        pos = 0
        i = 0

        while pos < to && i < @content.content.length
          child = @content.content[i]
          end_pos = pos + child.node_size

          if end_pos > from
            child_start = node_start + pos + 1
            if f.call(child, child_start,
                      i) != false && child.content.size.positive?
              child.nodes_between(
                [0, from - pos].max,
                [child.content.size, to - pos].min,
                f,
                child_start,
              )
            end
          end

          pos = end_pos
          i += 1
        end
      end

      def descendants(f)
        nodes_between(0, node_size, f)
      end

      def eq?(other)
        return false unless other.is_a?(Node)
        return false unless @type == other.type

        @attrs == other.attrs && @content.eq?(other.content) && same_marks?(other)
      end

      def same_marks?(other)
        return true if @marks.nil? && other.marks.nil?
        return false if @marks.nil? || other.marks.nil?
        return false unless @marks.length == other.marks.length

        @marks.each_with_index.all? do |m, i|
          m.type == other.marks[i].type && m.attrs == other.marks[i].attrs
        end
      end

      def to_h
        result = { "type" => @type.name }

        if @attrs && !@attrs.empty?
          result["attrs"] = @attrs
        end

        if @marks && !@marks.empty?
          result["marks"] = @marks.map(&:to_h)
        end

        if @content && !@content.empty?
          result["content"] = @content.content.map(&:to_h)
        end

        result
      end

      def to_s
        "<Node #{@type.name}>"
      end

      class << self
        def from_json(schema, json)
          type_name = json["type"]
          type = schema.node_type(type_name)

          attrs = json["attrs"] || {}
          content_data = json["content"]

          marks = if json["marks"].is_a?(Array)
                    json["marks"].map { |m| schema.mark_from_json(m) }
                  else
                    []
                  end

          # Handle text nodes specially
          if type.text?
            text = json["text"] || ""
            TextNode.new(type: type, attrs: attrs, text: text, marks: marks)
          else
            content = if content_data.is_a?(Array)
                        content_data.map { |c| from_json(schema, c) }
                      else
                        []
                      end
            Node.new(type: type, attrs: attrs, content: Fragment.new(content),
                     marks: marks)
          end
        end
      end
    end

    # Lightweight TextNode for schema validation
    class TextNode < Node
      attr_reader :text

      def initialize(type:, attrs: {}, text: "", marks: [])
        super(type: type, attrs: { text: text }, content: Fragment.empty, marks: marks)
        @text = text
      end

      def node_size
        @text.length + 1
      end

      def text_content
        @text
      end

      def cut(from = 0, to = nil)
        to ||= @text.length
        TextNode.new(type: @type, attrs: { text: @text[from...to] },
                     text: @text[from...to], marks: @marks)
      end

      def eq?(other)
        return false unless other.is_a?(TextNode)

        @text == other.text && super
      end

      def to_h
        result = { "type" => @type.name, "text" => @text }
        result["marks"] = @marks.map(&:to_h) if @marks && !@marks.empty?
        result
      end

      def to_s
        "<TextNode \"#{@text[0, 20]}\">"
      end
    end
  end
end
