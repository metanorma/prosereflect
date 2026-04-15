# frozen_string_literal: true

module Prosereflect
  class Schema
    # Represents a node specification from a schema
    class NodeSpec
      attr_reader :name, :attrs, :content, :groups, :inline, :atom, :marks

      def initialize(name:, attrs: {}, content: nil, groups: [], inline: false,
atom: false, marks: nil)
        @name = name
        @attrs = attrs
        @content = content
        @groups = groups
        @inline = inline
        @atom = atom
        @marks = marks
      end

      def self.from_hash(name, spec)
        new(
          name: name,
          attrs: spec[:attrs] || spec["attrs"] || {},
          content: spec[:content] || spec["content"],
          groups: parse_groups(spec),
          inline: spec[:inline] || spec["inline"] || false,
          atom: spec[:atom] || spec["atom"] || false,
          marks: spec[:marks] || spec["marks"],
        )
      end

      def self.parse_groups(spec)
        group_str = spec[:group] || spec["group"]
        return [] unless group_str

        group_str.is_a?(Array) ? group_str : group_str.to_s.split
      end
    end

    # Represents a mark specification from a schema
    class MarkSpec
      attr_reader :name, :attrs, :excludes, :inclusive, :group

      def initialize(name:, attrs: {}, excludes: nil, inclusive: true,
group: nil)
        @name = name
        @attrs = attrs
        @excludes = excludes
        @inclusive = inclusive
        @group = group
      end

      def self.from_hash(name, spec)
        new(
          name: name,
          attrs: spec[:attrs] || spec["attrs"] || {},
          excludes: spec[:excludes] || spec["excludes"],
          inclusive: if spec.key?(:inclusive)
                       spec[:inclusive]
                     elsif spec.key?("inclusive")
                       spec["inclusive"]
                     else
                       true
                     end,
          group: spec[:group] || spec["group"],
        )
      end
    end

    # Represents a complete schema specification
    class SchemaSpec
      attr_reader :nodes, :marks, :top_node

      def initialize(nodes: {}, marks: {}, top_node: nil)
        @nodes = nodes
        @marks = marks
        @top_node = top_node || "doc"
      end

      def self.from_hashes(nodes_spec:, marks_spec: {}, top_node: nil)
        nodes = nodes_spec.each_with_object({}) do |(name, spec), hash|
          hash[name] = NodeSpec.from_hash(name, spec)
        end
        marks = marks_spec.each_with_object({}) do |(name, spec), hash|
          hash[name] = MarkSpec.from_hash(name, spec)
        end

        new(nodes: nodes, marks: marks, top_node: top_node)
      end
    end
  end
end
