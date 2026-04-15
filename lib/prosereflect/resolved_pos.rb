# frozen_string_literal: true

module Prosereflect
  # ResolvedPos represents a document position that has been resolved
  # to a specific location in the document tree.
  #
  # The path array contains: [parent_node, index, start, parent_node, index, start, ...]
  # depth 0 = before any nodes, depth N = inside node at path[N*2]
  class ResolvedPos
    attr_reader :pos, :path, :depth

    def initialize(pos, path, depth)
      @pos = pos
      @path = path
      @depth = depth
      @parent_offset = nil
    end

    # The parent node at current depth
    def parent
      @path[@depth * 3]
    end

    # Index within parent
    def index(depth = @depth)
      @path[(depth * 3) + 1]
    end

    # Start position of current parent node
    def start(depth = @depth)
      @path[(depth * 3) + 2]
    end

    # End position of current parent node
    def end_(depth = @depth)
      start(depth) + parent.content.size
    end

    # The node at a given depth
    def node(depth = @depth)
      @path[depth * 3]
    end

    # Position within the parent node
    def parent_offset
      @parent_offset ||= @pos - start
    end

    # Marks at this position
    def marks
      if depth.zero?
        # At root - no marks
        []
      else
        parent_mark = parent.respond_to?(:marks) ? parent.marks : []
        parent_mark || []
      end
    end

    # Marks between two positions
    def marks_between(from, to, marks)
      result = marks.dup
      nodes_between(from, to) do |node|
        if node.respond_to?(:marks) && node.marks
          result = result | node.marks
        end
      end
      result
    end

    # Find shared depth with another position
    def shared_depth(other_pos)
      my_depth = depth
      other_depth = other_pos.depth

      while my_depth > other_depth
        my_depth -= 1
      end

      while other_depth > my_depth
        other_depth -= 1
      end

      while my_depth.positive?
        break unless index(my_depth) == other_pos.index(my_depth)

        my_depth -= 1

      end

      my_depth
    end

    # Get block range to another position
    def block_range(other_pos = nil)
      other_pos ||= self
      NodeRange.new(self, other_pos)
    end

    # Check if at block boundary
    def block?
      parent.respond_to?(:is_block?) && parent.is_block?
    end

    # Check if at inline boundary
    def inline?
      !block?
    end

    # Check if in text block
    def text_block?
      parent.respond_to?(:is_textblock?) && parent.is_textblock?
    end

    # Check if at start of parent
    def start_of_parent?
      parent_offset.zero?
    end

    # Check if at end of parent
    def end_of_parent?
      parent_offset >= parent.content.size - 1
    end

    # Get position before current node
    def before?
      if depth.zero?
        @pos.zero?
      else
        index.zero?
      end
    end

    # Get position after current node
    def after?
      if depth.zero?
        @pos >= 0
      else
        index >= parent.content.size
      end
    end

    def eq?(other)
      return false unless other.is_a?(ResolvedPos)

      @pos == other.pos && @depth == other.depth
    end

    alias == eq?

    def hash
      [@pos, @depth].hash
    end

    def to_s
      "<ResolvedPos #{@pos}:#{depth}>"
    end

    def inspect
      to_s
    end

    private

    def nodes_between(from, to, &block)
      return unless to > from

      depth.times do |d|
        node = node(d)
        node.nodes_between(from, to, &block) if node.respond_to?(:nodes_between)
      end
    end
  end

  # NodeRange represents a range between two resolved positions
  class NodeRange
    attr_reader :start, :end_

    alias end end_

    def initialize(start_resolved, end_resolved)
      @start = start_resolved
      @end_ = end_resolved
    end

    # Content fragment between start and end
    def content
      # Would extract the fragment
      Fragment.new([])
    end

    # Nodes within this range
    def nodes
      result = []
      start.node.nodes_between(start.pos, end_.pos) { |n| result << n }
      result
    end

    def to_s
      "<NodeRange #{start.pos}:#{end_.pos}>"
    end

    def inspect
      to_s
    end
  end

  # Extension to Node for position resolution
  class Node
    # Resolve a position to a ResolvedPos
    def resolve(pos)
      path = []
      build_path_for_pos(pos, path)
      depth = [(path.length / 3) - 1, 0].max
      ResolvedPos.new(pos, path, depth)
    end

    private

    def find_block_depth(common_depth)
      block_depth = common_depth
      while block_depth.positive?
        current_node = node(block_depth)
        break if current_node.respond_to?(:is_block?) && current_node.is_block?

        block_depth -= 1
      end
      block_depth
    end

    def build_path_for_pos(pos, path, index = 0, start_offset = 0)
      path << self << index << start_offset
      return if pos.zero?

      traverse_children_for_resolve(pos, path)
    end

    def traverse_children_for_resolve(pos, path)
      return unless content

      content_offset = 1
      child_index = 0

      content.each do |child|
        child_end = content_offset + child.node_size
        if pos < child_end
          child.send(:build_path_for_pos, pos - content_offset, path, child_index, content_offset)
          return
        end

        content_offset = child_end
        child_index += 1
      end
    end
  end
end
