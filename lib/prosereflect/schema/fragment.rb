# frozen_string_literal: true

module Prosereflect
  class Schema
    # Lightweight Fragment class for schema validation
    # This is a minimal implementation focused on the operations needed by ContentMatch
    class Fragment
      attr_reader :content

      def initialize(content = [])
        @content = content.is_a?(Array) ? content : [content].compact
      end

      def size
        @content.sum(&:node_size)
      end

      def empty?
        @content.empty?
      end

      def first
        @content.first
      end

      def last
        @content.last
      end

      def [](index)
        @content[index]
      end

      def []=(index, value)
        @content[index] = value
      end

      def length
        @content.length
      end

      def each(&block)
        @content.each(&block)
      end

      def <<(node)
        @content << node
        self
      end

      def append(other)
        return self if other.empty?
        return other if empty?

        last_node = @content.last
        first_other = other.first

        if last_node.text? && first_other.text? && last_node.same_markup?(first_other)
          merged = last_node.with_text(last_node.text + first_other.text)
          new_content = @content[0...-1] + [merged] + other.content[1..]
          Fragment.new(new_content)
        else
          Fragment.new(@content + other.content)
        end
      end

      def cut(from = 0, to = nil)
        to ||= size
        return Fragment.empty if from.zero? && to == size

        return Fragment.empty if to <= from

        result = []
        pos = 0
        i = 0

        while pos < to && i < @content.length
          child = @content[i]
          child_end = pos + child.node_size

          if child_end > from
            if pos < from || child_end > to
              if child.text?
                start_offset = [0, from - pos].max
                end_offset = [child.text.length, to - pos].min
              else
                start_offset = [0, from - pos - 1].max
                end_offset = [child.content.size, to - pos - 1].min
              end
              cut_child = child.cut(start_offset, end_offset)
              result << cut_child if cut_child
            else
              result << child
            end
          end

          pos = child_end
          i += 1
        end

        Fragment.new(result)
      end

      def replace_child(index, replacement)
        return self if @content[index] == replacement

        new_content = @content.dup
        new_content[index] = replacement
        Fragment.new(new_content)
      end

      def eq?(other)
        return false unless @content.length == other.content.length

        @content.each_with_index.all? { |node, i| node.eq?(other.content[i]) }
      end

      def nodes_between(from, to, f, node_start = 0)
        i = 0
        pos = 0

        while pos < to && i < @content.length
          child = @content[i]
          end_pos = pos + child.node_size

          if end_pos > from && f.call(child, node_start + pos,
                                      i) != false && child.content.size.positive?
            child.nodes_between(
              [0, from - pos].max,
              [child.content.size, to - pos].min,
              f,
              node_start + pos + 1,
            )
          end

          pos = end_pos
          i += 1
        end
      end

      def descendants(f)
        nodes_between(0, size, f)
      end

      def to_s
        "<#{@content.join(', ')}>"
      end

      class << self
        def empty
          @empty ||= new([])
        end

        def from(nodes)
          return empty if nodes.nil? || (nodes.is_a?(Array) && nodes.empty?)

          case nodes
          when Fragment then nodes
          when Array then new(nodes)
          else new([nodes])
          end
        end
      end
    end
  end
end
