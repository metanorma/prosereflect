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

        Result.ok(set_node_attrs(doc))
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
        doc.map_node_at(@pos) { |node| node.copy(node.content, compute_new_attrs(node)) }
      end

      def compute_new_attrs(target_node)
        (target_node.attrs || {}).merge(@attrs).compact
      end

      def get_old_attrs(doc)
        target_node = doc.node_at(@pos)
        return {} unless target_node

        @attrs.keys.to_h do |key|
          [key, target_node.attrs&.[](key)]
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
