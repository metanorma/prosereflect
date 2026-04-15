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

        # Build the new document
        new_doc = apply_replace(doc)
        Result.ok(new_doc)
      rescue StandardError => e
        Result.fail(e.message)
      end

      def get_map
        delta = @slice.size - (@to - @from)
        StepMap.new([[@from, @to, @from, @from + delta]])
      end

      def invert(doc)
        # Find what was removed
        removed = content_between(doc, @from, @to)
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

      def apply_replace(doc)
        # Get content before, during, and after the replaced range
        before = content_before(doc, @from)
        after = content_after(doc, @to)

        # Build new document
        new_content = []
        new_content.concat(before) unless before.empty?
        new_content.concat(@slice.content.to_a) unless @slice.empty?
        new_content.concat(after) unless after.empty?

        rebuild_doc(doc, new_content)
      end

      def content_before(doc, pos)
        result = []
        doc.nodes_between(0, pos) { |node| result << node }
        result
      end

      def content_after(doc, pos)
        result = []
        doc.nodes_between(pos, doc.node_size) { |node| result << node }
        result
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

      def rebuild_doc(doc, new_content)
        # Create a new document with the same structure but new content
        attrs = doc.attrs.dup
        Fragment.new(new_content)
        # For simplicity, return a new Document with the new content
        # In reality this would preserve the doc type
        doc.class.new(content: Fragment.new(new_content), attrs: attrs)
      end
    end
  end
end
