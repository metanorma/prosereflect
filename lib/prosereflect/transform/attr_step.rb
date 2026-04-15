# frozen_string_literal: true

require_relative "step"
require_relative "step_map"

module Prosereflect
  module Transform
    # Set or remove attributes on a node at a position
    class AttrStep < Step
      attr_reader :pos, :attrs

      def initialize(pos, attrs)
        super()
        @pos = pos
        @attrs = attrs
      end

      def apply(doc)
        return Result.fail("Invalid position") if @pos.negative? || @pos > doc.node_size

        begin
          new_doc = set_node_attrs(doc)
          Result.ok(new_doc)
        rescue StandardError => e
          Result.fail(e.message)
        end
      end

      def get_map
        StepMap.new
      end

      def invert(doc)
        # Find what attrs were changed and revert them
        old_attrs = get_old_attrs(doc)
        AttrStep.new(@pos, old_attrs)
      end

      def step_type
        "setAttr"
      end

      def to_json(*_args)
        json = super
        json["pos"] = @pos
        json["attrs"] = @attrs
        json
      end

      def self.from_json(_schema, json)
        new(json["pos"], json["attrs"])
      end

      private

      def set_node_attrs(doc)
        target_node = find_node_at(doc, @pos)
        return doc unless target_node

        new_attrs = compute_new_attrs(target_node)
        replace_node_with_new_attrs(doc, target_node, new_attrs)
      end

      def compute_new_attrs(target_node)
        new_attrs = target_node.attrs.merge(@attrs)
        new_attrs.compact!
        new_attrs
      end

      def replace_node_with_new_attrs(doc, target_node, new_attrs)
        new_content = doc.content.to_a.map { |node| replace_node(node, target_node, new_attrs) }
        doc.class.new(content: Fragment.new(new_content), attrs: doc.attrs.dup)
      end

      def replace_node(node, target_node, new_attrs)
        return node unless node == target_node

        node.class.new(
          content: node.content,
          marks: node.marks,
          attrs: new_attrs,
        )
      end

      def find_node_at(doc, pos)
        result = nil
        doc.nodes_between(pos, pos + 1) do |node|
          result = node
        end
        result
      end

      def get_old_attrs(doc)
        target_node = find_node_at(doc, @pos)
        return {} unless target_node

        # Return only the attrs that we're changing
        @attrs.keys.each_with_object({}) do |key, old|
          old[key] = target_node.attrs[key] if target_node.attrs.key?(key)
        end
      end
    end

    # Set or remove document-level attributes
    class DocAttrStep < Step
      attr_reader :attrs

      def initialize(attrs)
        super()
        @attrs = attrs
      end

      def apply(doc)
        new_doc = set_doc_attrs(doc)
        Result.ok(new_doc)
      rescue StandardError => e
        Result.fail(e.message)
      end

      def get_map
        StepMap.new
      end

      def invert(doc)
        old_attrs = get_old_doc_attrs(doc)
        DocAttrStep.new(old_attrs)
      end

      def step_type
        "setDocAttr"
      end

      def to_json(*_args)
        json = super
        json["attrs"] = @attrs
        json
      end

      def self.from_json(_schema, json)
        new(json["attrs"])
      end

      private

      def set_doc_attrs(doc)
        new_attrs = doc.attrs.merge(@attrs).compact
        doc.class.new(content: doc.content, attrs: new_attrs)
      end

      def get_old_doc_attrs(doc)
        @attrs.keys.each_with_object({}) do |key, old|
          old[key] = doc.attrs[key] if doc.attrs.key?(key)
        end
      end
    end
  end
end
