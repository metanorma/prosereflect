# frozen_string_literal: true

require_relative "step"

module Prosereflect
  module Transform
    # Replaces a range of the document with a slice of content,
    # but also replaces the content before and after the gap.
    # Used by lift and wrap operations.
    class ReplaceAroundStep < Step
      attr_reader :from, :to, :gap_from, :gap_to, :slice, :insert, :structure

      def initialize(from, to, gap_from, gap_to, slice, insert, structure: false)
        super()
        @from = from
        @to = to
        @gap_from = gap_from
        @gap_to = gap_to
        @slice = slice
        @insert = insert
        @structure = structure
      end

      def apply(doc)
        # Check structure constraint
        if @structure && (content_between(doc, @from, @gap_from) || content_between(doc, @gap_to, @to))
          return Result.fail("Structure gap-replace would overwrite content")
        end

        # Get the gap content
        gap = doc.slice(@gap_from, @gap_to)
        if gap.open_start || gap.open_end
          return Result.fail("Gap is not a flat range")
        end

        # Try to insert slice into gap
        inserted = @slice.insert_at(@insert, gap.content)
        unless inserted
          return Result.fail("Content does not fit in gap")
        end

        # Apply the replacement
        new_doc = apply_replace_around(doc, inserted)
        Result.ok(new_doc)
      rescue StandardError => e
        Result.fail(e.message)
      end

      def get_map
        StepMap.new([
                      @from,
                      @gap_from - @from,
                      @insert,
                      @gap_to,
                      @to - @gap_to,
                      @slice.size - @insert,
                    ])
      end

      def invert(doc)
        gap = @gap_to - @gap_from
        removed = doc.slice(@from, @to).remove_between(
          @gap_from - @from,
          @gap_to - @from,
        )
        ReplaceAroundStep.new(
          @from,
          @from + @slice.size + gap,
          @from + @insert,
          @from + @insert + gap,
          removed,
          @gap_from - @from,
          @structure,
        )
      end

      def map(mapping)
        from_mapped = mapping.map_result(@from, 1)
        to_mapped = mapping.map_result(@to, -1)

        gap_from_mapped = if @from == @gap_from
                            from_mapped.pos
                          else
                            mapping.map(@gap_from, -1)
                          end

        gap_to_mapped = if @to == @gap_to
                          to_mapped.pos
                        else
                          mapping.map(@gap_to, 1)
                        end

        if (from_mapped.deleted && to_mapped.deleted) || gap_from_mapped < from_mapped.pos || gap_to_mapped > to_mapped.pos
          return nil
        end

        ReplaceAroundStep.new(
          from_mapped.pos,
          to_mapped.pos,
          gap_from_mapped,
          gap_to_mapped,
          @slice,
          @insert,
          @structure,
        )
      end

      def step_type
        "replaceAround"
      end

      def to_json(*_args)
        json = super
        json["from"] = @from
        json["to"] = @to
        json["gapFrom"] = @gap_from
        json["gapTo"] = @gap_to
        json["slice"] = @slice.content.to_a.map(&:to_h)
        json["insert"] = @insert
        json["structure"] = @structure
        json
      end

      def self.from_json(_schema, json)
        from_val = json["from"]
        to_val = json["to"]
        gap_from_val = json["gapFrom"]
        gap_to_val = json["gapTo"]
        insert_val = json["insert"]
        structure_val = json["structure"] || false

        slice_json = json["slice"] || []
        slice_content = slice_json.map { |h| Prosereflect::Node.from_h(h) }
        slice = Slice.new(Fragment.new(slice_content))

        new(from_val, to_val, gap_from_val, gap_to_val, slice, insert_val, structure: structure_val)
      end

      private

      def content_between(doc, from, to)
        return nil if from >= to

        result = []
        doc.nodes_between(from, to) { |node| result << node }
        result.empty? ? nil : Fragment.new(result)
      end

      def apply_replace_around(doc, inserted)
        # Get content before and after the replaced range
        before = content_before(doc, @from)
        after = content_after(doc, @to)

        # Build new document
        new_content = []
        new_content.concat(before) unless before.empty?
        new_content.concat(inserted.content.to_a) unless inserted.empty?
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

      def rebuild_doc(doc, new_content)
        attrs = doc.attrs.dup
        doc.class.new(content: Fragment.new(new_content), attrs: attrs)
      end
    end
  end
end
