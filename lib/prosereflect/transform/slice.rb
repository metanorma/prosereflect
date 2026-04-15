# frozen_string_literal: true

module Prosereflect
  module Transform
    # Represents a slice of a document - a contiguous portion that can be
    # inserted, deleted, or moved. Tracks open boundaries for proper joining.
    class Slice
      attr_reader :content, :open_start, :open_end

      def initialize(content, open_start = 0, open_end = 0)
        @content = content
        @open_start = open_start
        @open_end = open_end
      end

      # Check if this slice is empty (no content and no open boundaries)
      def empty?
        @content.empty? && @open_start.zero? && @open_end.zero?
      end

      # Total size of the slice including open boundaries
      def size
        content_size + @open_start + @open_end
      end

      # Size of just the content
      def content_size
        size = 0
        @content.each { |node| size += node.node_size }
        size
      end

      # Cut the slice at given boundaries
      def cut(from = 0, to = nil)
        to ||= size

        if from.zero? && to == size
          return self
        end

        result = cut_internal(from, to)
        Slice.new(result[:content], result[:open_start], result[:open_end])
      end

      # Check equality
      def eq?(other)
        return false unless other.is_a?(Slice)

        @open_start == other.open_start &&
          @open_end == other.open_end &&
          @content.to_a.map(&:to_h) == other.content.to_a.map(&:to_h)
      end

      alias == eq?

      def to_s
        "<Slice open_start=#{@open_start} open_end=#{@open_end} content=#{@content.length} items>"
      end

      def inspect
        to_s
      end

      # Create an empty slice
      def self.empty
        new(Fragment.new([]), 0, 0)
      end

      private

      def cut_internal(from, to)
        return { content: @content, open_start: @open_start, open_end: @open_end } if from >= to

        # Simplified cut - just adjusts open flags
        new_open_start = @open_start
        new_open_end = @open_end
        new_content = @content

        if from.positive?
          new_open_start = [new_open_start - from, 0].max
        end

        if to < size
          new_open_end = [new_open_end - (size - to), 0].max
        end

        { content: new_content, open_start: new_open_start, open_end: new_open_end }
      end
    end
  end
end
