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
    end

    # Add a mark to all content in a range
    class AddMarkStep < MarkStep
      def apply(doc)
        return Result.fail("Invalid positions") if @from > @to || @from.negative?

        begin
          new_doc = add_mark_to_range(doc)
          Result.ok(new_doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
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

      def to_json(*_args)
        json = super
        json["mark"] = @mark.to_h
        json
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(json["from"], json["to"], mark)
      end

      private

      def add_mark_to_range(doc)
        new_content = doc.content.map { |node| apply_mark_to_node(node) }
        doc.class.new(content: Fragment.new(new_content), attrs: doc.attrs.dup)
      end

      def apply_mark_to_node(node)
        return node unless node.is_a?(Prosereflect::Text)

        Prosereflect::Text.new(
          text: node.text,
          marks: (node.marks || []) + [@mark],
          attrs: node.attrs.dup,
        )
      end

      def remove_mark_from_range(doc)
        new_content = doc.content.map { |node| remove_mark_from_node_single(node) }
        doc.class.new(content: Fragment.new(new_content), attrs: doc.attrs.dup)
      end

      def remove_mark_from_node_single(node)
        return node unless node.is_a?(Prosereflect::Text)

        new_marks = (node.marks || []).reject { |m| m.type == @mark.type }
        Prosereflect::Text.new(
          text: node.text,
          marks: new_marks,
          attrs: node.attrs.dup,
        )
      end
    end

    # Remove a mark from all content in a range
    class RemoveMarkStep < MarkStep
      def apply(doc)
        return Result.fail("Invalid positions") if @from > @to || @from.negative?

        begin
          new_doc = remove_mark_from_range(doc)
          Result.ok(new_doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
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

      def to_json(*_args)
        json = super
        json["mark"] = @mark.to_h
        json
      end

      def self.from_json(_schema, json)
        mark = Prosereflect::Mark.from_h(json["mark"])
        new(json["from"], json["to"], mark)
      end
    end

    # Add mark to a specific node (not range-based)
    class AddNodeMarkStep < Step
      attr_reader :pos, :mark

      def initialize(pos, mark)
        super()
        @pos = pos
        @mark = mark
      end

      def apply(doc)
        return Result.fail("Invalid position") if @pos.negative? || @pos > doc.node_size

        begin
          new_doc = add_mark_to_node(doc)
          Result.ok(new_doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
      end

      def get_map
        StepMap.new
      end

      def invert(_doc)
        RemoveNodeMarkStep.new(@pos, @mark)
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
        new(json["pos"], mark)
      end

      private

      def add_mark_to_node(doc)
        new_content = doc.content.map { |node| add_mark_to_single_node(node) }
        doc.class.new(content: Fragment.new(new_content), attrs: doc.attrs.dup)
      end

      def add_mark_to_single_node(node)
        new_marks = (node.marks || []) + [@mark]
        node.class.new(
          content: node.content,
          marks: new_marks,
          attrs: node.attrs.dup,
        )
      end
    end

    # Remove mark from a specific node
    class RemoveNodeMarkStep < Step
      attr_reader :pos, :mark

      def initialize(pos, mark)
        super()
        @pos = pos
        @mark = mark
      end

      def apply(doc)
        return Result.fail("Invalid position") if @pos.negative? || @pos > doc.node_size

        begin
          new_doc = remove_mark_from_node(doc)
          Result.ok(new_doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
      end

      def get_map
        StepMap.new
      end

      def invert(_doc)
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
        new(json["pos"], mark)
      end

      private

      def remove_mark_from_node(doc)
        new_content = doc.content.map { |node| remove_mark_from_single_node(node) }
        doc.class.new(content: Fragment.new(new_content), attrs: doc.attrs.dup)
      end

      def remove_mark_from_single_node(node)
        new_marks = (node.marks || []).reject { |m| m.type == @mark.type }
        node.class.new(
          content: node.content,
          marks: new_marks,
          attrs: node.attrs.dup,
        )
      end
    end
  end
end
