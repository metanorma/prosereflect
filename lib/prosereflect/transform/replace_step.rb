# frozen_string_literal: true

require_relative "step"

module Prosereflect
  module Transform
    # Replaces a range of the document with a slice of content.
    class ReplaceStep < Step
      attr_reader :from, :to, :slice

      def initialize(from, to, slice = Slice.empty)
        super()
        @from = from
        @to = to
        @slice = slice
      end

      def apply(doc)
        # Validate positions
        return Result.fail("Invalid positions") if @from > @to
        return Result.fail("from < 0") if @from.negative?
        return Result.fail("to > doc size") if @to > doc.node_size
        return Result.fail("Slice open boundaries are not supported") if open_boundaries?

        Result.ok(doc.replace(@from, @to, @slice.content.to_a))
      rescue StandardError => e
        Result.fail(e.message)
      end

      def get_map
        delta = @slice.size - (@to - @from)
        StepMap.new([[@from, @to, @from, @from + delta]])
      end

      def invert(doc)
        # Find what was removed. Wrapped in a Slice because a step's slice is a
        # Slice, not a Fragment: apply reads open_start/open_end off it.
        removed = Slice.new(content_between(doc, @from, @to))
        ReplaceStep.new(@from, @from + @slice.size, removed)
      end

      def merge(other)
        return nil unless other.is_a?(ReplaceStep)

        return extend_deletion(other) if can_extend_deletion?(other)
        return prepend_deletion(other) if can_prepend_deletion?(other)
        return append_content(other) if can_append_content?(other)
        return prepend_content(other) if can_prepend_content?(other)

        nil
      end

      def can_extend_deletion?(other)
        @to == other.from && @slice.empty?
      end

      def extend_deletion(other)
        ReplaceStep.new(@from, other.to, Slice.empty)
      end

      def can_prepend_deletion?(other)
        other.to == @from && other.slice.empty?
      end

      def prepend_deletion(other)
        ReplaceStep.new(other.from, @to, Slice.empty)
      end

      def can_append_content?(other)
        @to == other.from && !other.slice.empty?
      end

      def append_content(other)
        new_content = join_slices(@slice, other.slice)
        ReplaceStep.new(@from, other.to, new_content)
      end

      def can_prepend_content?(other)
        other.to == @from && !other.slice.empty?
      end

      def prepend_content(other)
        new_content = join_slices(other.slice, @slice)
        ReplaceStep.new(other.from, @to, new_content)
      end

      def step_type
        "replace"
      end

      def to_json(*_args)
        json = super
        json["from"] = @from
        json["to"] = @to
        json["slice"] = @slice.content.map(&:to_h)
        json
      end

      def self.from_json(_schema, json)
        from_val = json["from"]
        to_val = json["to"]
        slice_json = json["slice"] || []
        slice_content = slice_json.map { |h| Prosereflect::Node.from_h(h) }
        slice = Slice.new(Fragment.new(slice_content))
        new(from_val, to_val, slice)
      end

      private

      # Open depths describe how the slice's content joins at its boundaries, so
      # they are inert when there is no content to join.
      def open_boundaries?
        return false if @slice.content.empty?

        !@slice.open_start.zero? || !@slice.open_end.zero?
      end

      def content_between(doc, from, to)
        result = []
        doc.nodes_between(from, to) { |node| result << node }
        Fragment.new(result)
      end

      def join_slices(left, right)
        new_content = Fragment.new(left.content.to_a + right.content.to_a)
        Slice.new(new_content, left.open_start, right.open_end)
      end
    end
  end
end
