# frozen_string_literal: true

require_relative "step"
require_relative "step_map"

module Prosereflect
  module Transform
    # Base class for mark-related steps
    class MarkStep < Step
      attr_reader :from, :to, :mark

      def initialize(from, to, mark)
        super()
        @from = from
        @to = to
        @mark = mark
      end

      def get_map
        StepMap.new
      end

      def to_json(*_args)
        { "stepType" => step_type, "from" => @from, "to" => @to, "mark" => @mark.to_h }
      end
    end

    # Add a mark to all content in a range
    class AddMarkStep < MarkStep
      def apply(doc)
        return Result.fail("Invalid positions") if @from.negative? || @from > @to || @to > doc.node_size

        Result.ok(doc.update_marks(@from, @to) { |marks| @mark.add_to_set(marks) })
      end

      def invert(_doc)
        RemoveMarkStep.new(@from, @to, @mark)
      end

      def merge(other)
        return nil unless other.is_a?(AddMarkStep)
        return nil unless other.mark == @mark

        if @to == other.from
          AddMarkStep.new(@from, other.to, @mark)
        elsif @from == other.to
          AddMarkStep.new(other.from, @to, @mark)
        end
      end

      def step_type
        "addMark"
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(integer_position(json, "from"), integer_position(json, "to"), mark)
      end
    end

    # Remove a mark from all content in a range
    class RemoveMarkStep < MarkStep
      def apply(doc)
        return Result.fail("Invalid positions") if @from.negative? || @from > @to || @to > doc.node_size

        Result.ok(doc.update_marks(@from, @to) { |marks| @mark.remove_from_set(marks) })
      end

      def invert(_doc)
        AddMarkStep.new(@from, @to, @mark)
      end

      def merge(other)
        return nil unless other.is_a?(RemoveMarkStep)
        return nil unless other.mark == @mark

        if @to == other.from
          RemoveMarkStep.new(@from, other.to, @mark)
        elsif @from == other.to
          RemoveMarkStep.new(other.from, @to, @mark)
        end
      end

      def step_type
        "removeMark"
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(integer_position(json, "from"), integer_position(json, "to"), mark)
      end
    end

    # Add mark to a specific node (not range-based).
    # `pos` addresses a node token, so pos 0 addresses the document node itself.
    class AddNodeMarkStep < Step
      attr_reader :pos, :mark

      def initialize(pos, mark)
        super()
        @pos = pos
        @mark = mark
      end

      def apply(doc)
        return Result.fail("Invalid position") unless position_in_bounds?(@pos, doc)

        Result.ok(doc.map_node_at(@pos) { |node| node.with_marks(@mark.add_to_set(node.raw_marks || [])) })
      end

      def get_map
        StepMap.new
      end

      # `doc` is the document as it stood before this step ran. Adding a mark of a
      # type the node already carries replaces the old one, and only the pre-step
      # tree still knows what was replaced. Re-adding the displaced mark restores
      # it; when the node already carried this exact mark the step changed
      # nothing, and re-adding it undoes nothing, which is the right inverse.
      def invert(doc)
        displaced = @mark.displaced_from(doc.node_at(@pos)&.raw_marks || [])
        return RemoveNodeMarkStep.new(@pos, @mark) unless displaced

        AddNodeMarkStep.new(@pos, displaced)
      end

      def step_type
        "addNodeMark"
      end

      def to_json(*_args)
        json = super
        json["pos"] = @pos
        json["mark"] = @mark.to_h
        json
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(integer_position(json, "pos"), mark)
      end
    end

    # Remove mark from a specific node.
    # `pos` addresses a node token, so pos 0 addresses the document node itself.
    class RemoveNodeMarkStep < Step
      attr_reader :pos, :mark

      def initialize(pos, mark)
        super()
        @pos = pos
        @mark = mark
      end

      def apply(doc)
        return Result.fail("Invalid position") unless position_in_bounds?(@pos, doc)

        Result.ok(doc.map_node_at(@pos) { |node| node.with_marks(@mark.remove_from_set(node.raw_marks || [])) })
      end

      def get_map
        StepMap.new
      end

      # `doc` is the document as it stood before this step ran. Removing a mark
      # the node never carried changes nothing, and the inverse of changing
      # nothing is this same step, not an add that would inject the mark.
      def invert(doc)
        node = doc.node_at(@pos)
        return self unless node && @mark.is_in_set?(node.raw_marks || [])

        AddNodeMarkStep.new(@pos, @mark)
      end

      def step_type
        "removeNodeMark"
      end

      def to_json(*_args)
        json = super
        json["pos"] = @pos
        json["mark"] = @mark.to_h
        json
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(integer_position(json, "pos"), mark)
      end
    end
  end
end
