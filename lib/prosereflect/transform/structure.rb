# frozen_string_literal: true

require_relative "step"
require_relative "replace_step"

module Prosereflect
  module Transform
    # Structure predicates and helpers for document manipulation
    class Structure
      class << self
        # Check if we can split at a position
        # Returns true if the position allows a split (e.g., inside a text node)
        def can_split?(doc, pos, types = nil)
          return false if pos.negative? || pos > doc.node_size

          resolved = doc.resolve(pos)
          parent = resolved.parent

          return false unless parent.respond_to?(:content)

          node_type = parent.respond_to?(:type) ? parent.type : nil

          if types
            types.all? { |t| t.respond_to?(:name) ? t.name == node_type : t == node_type }
          else
            true
          end
        end

        # Find the target depth for lifting content out of a wrapper
        # Returns the depth to which content should be lifted
        def lift_target(fragment, from, to)
          depth = 0
          pos = 0

          fragment.content.each do |node|
            node_end = pos + node.node_size
            break if pos >= to

            # This node is within the range being lifted
            if pos < to && node_end > from && node.respond_to?(:defining?) && node.defining?
              depth += 1
            end

            pos = node_end
          end

          depth
        end

        # Find wrapper nodes needed to wrap a range
        # Returns array of node types that would wrap the range
        def find_wrapping(fragment, _from, to, node_type, attrs = nil)
          wrappers = []
          current_depth = 0
          pos = 0

          fragment.content.each do |node|
            node_end = pos + node.node_size
            break if pos >= to

            if node.respond_to?(:defining?) && node.defining? && current_depth.zero?
              # Found a defining node at the boundary
              wrappers << build_wrapper(node_type, attrs)
            end

            pos = node_end
          end

          wrappers
        end

        # Check if nodes can be joined at a position
        def can_join?(doc, pos)
          return false if pos <= 0 || pos >= doc.node_size

          resolved = doc.resolve(pos)

          # We need to be at a boundary between two children
          # Check the node at the depth where we're at a child boundary
          depth = resolved.depth
          return false unless depth.positive?

          parent = resolved.node(depth - 1)
          return false unless parent.respond_to?(:content)
          return false if parent.content.nil?

          index = resolved.index(depth)
          return false unless index.positive? && index < parent.content.size

          prev_node = parent.content[index - 1]
          next_node = parent.content[index]

          prev_node.type == next_node.type
        end

        # Find positions where a join can happen
        def join_point?(doc, pos)
          return false unless can_join?(doc, pos)

          pos
        end

        private

        def build_wrapper(node_type, attrs)
          if node_type.is_a?(String)
            Prosereflect::Node.from_h(
              "type" => node_type,
              "attrs" => attrs || {},
              "content" => [],
            )
          else
            node_type
          end
        end
      end
    end
  end
end
