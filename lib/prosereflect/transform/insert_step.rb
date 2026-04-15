# frozen_string_literal: true

require_relative "step"
require_relative "step_map"
require_relative "replace_step"
require_relative "slice"

module Prosereflect
  module Transform
    # Insert content at a position
    class InsertStep < Step
      attr_reader :pos, :content

      def initialize(pos, content)
        super()
        @pos = pos
        @content = content.is_a?(Fragment) ? content : Fragment.new(content)
      end

      def apply(doc)
        return Result.fail("Invalid position") if @pos.negative? || @pos > doc.node_size

        begin
          slice = Slice.new(@content)
          replace_step = ReplaceStep.new(@pos, @pos, slice)
          replace_step.apply(doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
      end

      def get_map
        delta = @content.size
        StepMap.new([[@pos, @pos, @pos, @pos + delta]])
      end

      def invert(_doc)
        DeleteStep.new(@pos, @pos + @content.size)
      end

      def step_type
        "insert"
      end

      def to_json(*_args)
        json = super
        json["pos"] = @pos
        json["content"] = @content.to_a.map(&:to_h)
        json
      end

      def self.from_json(_schema, json)
        content = (json["content"] || []).map { |h| Prosereflect::Node.from_h(h) }
        new(json["pos"], Fragment.new(content))
      end
    end

    # Delete content in a range
    class DeleteStep < Step
      attr_reader :from, :to

      def initialize(from, to)
        super()
        @from = from
        @to = to
      end

      def apply(doc)
        return Result.fail("Invalid positions") if @from > @to
        return Result.fail("from < 0") if @from.negative?
        return Result.fail("to > doc size") if @to > doc.node_size

        begin
          replace_step = ReplaceStep.new(@from, @to, Slice.empty)
          replace_step.apply(doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
      end

      def get_map
        StepMap.delete(@from, @to)
      end

      def invert(doc)
        # Find what was deleted
        deleted = content_between(doc, @from, @to)
        InsertStep.new(@from, deleted)
      end

      def step_type
        "delete"
      end

      def to_json(*_args)
        json = super
        json["from"] = @from
        json["to"] = @to
        json
      end

      def self.from_json(_schema, json)
        new(json["from"], json["to"])
      end

      private

      def content_between(doc, from, to)
        result = []
        doc.nodes_between(from, to) { |node| result << node }
        Fragment.new(result)
      end
    end
  end
end
