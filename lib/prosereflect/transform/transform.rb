# frozen_string_literal: true

require_relative "step"
require_relative "step_map"
require_relative "mapping"
require_relative "slice"
require_relative "replace_step"
require_relative "replace_around_step"
require_relative "mark_step"
require_relative "attr_step"
require_relative "insert_step"

module Prosereflect
  module Transform
    # A chainable document transformation.
    # Accumulates steps and their mappings.
    class Transform
      attr_reader :steps, :mapping

      def initialize(doc)
        @doc = doc
        @steps = []
        @mapping = Mapping.new
      end

      # Add a mark to all content in range
      def add_mark(from, to, mark)
        add_step(AddMarkStep.new(from, to, mark))
      end

      # Remove a mark from all content in range
      def remove_mark(from, to, mark)
        add_step(RemoveMarkStep.new(from, to, mark))
      end

      # Insert content at position
      def insert(pos, content)
        add_step(InsertStep.new(pos, content))
      end

      # Delete content in range
      def delete(from, to)
        add_step(DeleteStep.new(from, to))
      end

      # Replace content in range with slice
      def replace(from, to, slice = Slice.empty)
        add_step(ReplaceStep.new(from, to, slice))
      end

      # Replace content with specific nodes
      def replace_with(from, to, *nodes)
        content = Fragment.new(nodes.flatten)
        slice = Slice.new(content)
        add_step(ReplaceStep.new(from, to, slice))
      end

      # Set attribute on node at position
      def set_node_attribute(pos, attrs)
        add_step(AttrStep.new(pos, attrs))
      end

      # Set document attribute
      def set_doc_attribute(attrs)
        add_step(DocAttrStep.new(attrs))
      end

      # Apply all accumulated steps to the document
      # Returns self for chaining
      def apply
        @steps.each do |step|
          result = step.apply(@doc)
          raise ApplyError, "Step #{step.class} failed: #{result.failed}" unless result.ok?

          @doc = result.doc
        end
        self
      end

      # Apply and return the transformed document
      def doc
        # Apply pending steps
        apply if @steps.any?
        @doc
      end

      # Check if any steps have been applied
      def empty?
        @steps.empty?
      end

      # Get the number of steps
      def size
        @steps.length
      end

      # Add a step and track its mapping
      def add_step(step)
        @steps << step
        @mapping.add_map(step.get_map)
        self
      end

      # Get the mapping for all applied steps
      def maps
        @mapping.to_a
      end

      # Create a new transform with the same document
      def clone
        Transform.new(@doc)
      end

      # Roll back the last step
      def rollback
        return self if @steps.empty?

        step = @steps.pop
        @mapping = Mapping.new(maps: @mapping.to_a[0...-1])

        inverted = step.invert(@doc)
        result = inverted.apply(@doc)
        if result.ok?
          @doc = result.doc
        end

        self
      end

      # Check if we can step forward
      def can_apply?
        @steps.all? { |step| step.apply(@doc).ok? }
      end

      # Add mark using schema
      def add_mark_by_type(from, to, mark_type_name, schema, attrs = nil)
        mark_type = schema.mark_type(mark_type_name)
        mark = mark_type.create(attrs)
        add_mark(from, to, mark)
      end

      # Remove mark using schema
      def remove_mark_by_type(from, to, mark_type_name, schema)
        mark_type = schema.mark_type(mark_type_name)
        mark = mark_type.create
        remove_mark(from, to, mark)
      end

      # Lift content out of a wrapper node
      # range: NodeRange representing the content to lift
      # target: depth to lift to
      def lift(range, target)
        from_ = range.from
        to_ = range.to
        depth = range.depth

        gap_start = position_before_depth(from_, depth + 1)
        gap_end = position_after_depth(to_, depth + 1)
        start = gap_start
        end_pos = gap_end

        before = Fragment.empty
        open_start = 0
        d = depth
        splitting = false
        while d > target
          if splitting || node_index_at_depth(from_, d).positive?
            splitting = true
            before = Fragment.from(node_at_depth(from_, d).copy(before))
            open_start += 1
          else
            start -= 1
          end
          d -= 1
        end

        after = Fragment.empty
        open_end = 0
        d = depth
        splitting = false
        while d > target
          if splitting || position_after_depth(to_, d + 1) < node_end_at_depth(to_, d)
            splitting = true
            after = Fragment.from(node_at_depth(to_, d).copy(after))
            open_end += 1
          else
            end_pos += 1
          end
          d -= 1
        end

        replace_around_step(
          start,
          end_pos,
          gap_start,
          gap_end,
          Slice.new(before.append(after), open_start, open_end),
          before.size - open_start,
          true,
        )
        self
      end

      # Wrap content in nodes
      # range: NodeRange representing the content to wrap
      # wrappers: array of NodeTypeWithAttrs representing wrapper nodes
      def wrap(range, wrappers)
        content = Fragment.empty
        i = wrappers.length - 1
        while i >= 0
          if content.size.positive?
            match = wrappers[i].type.content_match.match_fragment(content)
            unless match&.valid_end
              raise TransformError, "Wrapper type given to Transform.wrap does not form valid content of its parent wrapper"
            end
          end
          content = Fragment.from(
            wrappers[i].type.create(wrappers[i].attrs, content),
          )
          i -= 1
        end

        start = range.start
        end_pos = range.end
        replace_around_step(
          start,
          end_pos,
          start,
          end_pos,
          Slice.new(content, 0, 0),
          wrappers.length,
          true,
        )
        self
      end

      # Split a node at a position
      def split(pos, depth = 1)
        resolved = @doc.resolve(pos)
        before = Fragment.empty
        open_start = 0
        open_end = 0

        d = depth
        while d.positive?
          node = resolved.node(d)
          if d == depth
            before = Fragment.from(node.copy(Fragment.empty))
            open_start = node.is_a?(Prosereflect::Node) && node.content&.size.to_i.positive? ? 1 : 0
            open_end = 0
          else
            before = Fragment.from(node.copy(before))
            open_start += 1
          end
          d -= 1
        end

        step = ReplaceAroundStep.new(
          pos,
          pos,
          pos,
          pos,
          Slice.new(before, open_start, open_end),
          open_start,
          structure: false,
        )
        add_step(step)
        self
      end

      # Join two nodes at a position
      def join(pos, depth = 1)
        resolved = @doc.resolve(pos)
        d = depth
        while d.positive?
          # Check if we can join at this depth
          parent = resolved.node(d - 1) if d >= 1
          idx = resolved.index(d)

          if parent&.content && idx.positive? && idx < parent.content.size
            before_node = parent.content[idx - 1]
            after_node = parent.content[idx]

            if before_node.type == after_node.type
              # Join point is at the boundary between before_node and after_node
              join_from = resolved.start(d) - before_node.node_size
              join_to = resolved.start(d) + after_node.node_size
              replace(join_from, join_to, Slice.empty)
            end
          end
          d -= 1
        end
        self
      end

      class ApplyError < StandardError; end
      class TransformError < StandardError; end

      def to_s
        "<Transform steps=#{@steps.length}>"
      end

      def inspect
        to_s
      end

      private

      def replace_around_step(from, to, gap_from, gap_to, slice, insert, structure)
        add_step(ReplaceAroundStep.new(from, to, gap_from, gap_to, slice, insert, structure: structure))
      end

      def position_before_depth(pos, depth)
        resolved = @doc.resolve(pos)
        node = resolved.node(depth)
        pos - (node.is_a?(Prosereflect::Node) ? 1 : 0)
      end

      def position_after_depth(pos, depth)
        resolved = @doc.resolve(pos)
        node = resolved.node(depth)
        pos + (node.is_a?(Prosereflect::Node) ? 1 : 0)
      end

      def node_index_at_depth(pos, depth)
        resolved = @doc.resolve(pos)
        resolved.index(depth)
      end

      def node_at_depth(pos, depth)
        resolved = @doc.resolve(pos)
        resolved.node(depth)
      end

      def node_end_at_depth(pos, depth)
        resolved = @doc.resolve(pos)
        resolved.end(depth)
      end
    end
  end
end
