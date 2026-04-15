# frozen_string_literal: true

module Prosereflect
  # Fragment represents a sequence of nodes.
  # Used for document content, slice content, etc.
  class Fragment
    attr_reader :content

    def initialize(content = [])
      @content = if content.is_a?(Array)
                   content
                 elsif content.respond_to?(:to_a)
                   content.to_a
                 else
                   [content]
                 end
    end

    # Total size of all nodes in this fragment
    def size
      @content.sum { |n| n.respond_to?(:node_size) ? n.node_size : n.text_content.length + 1 }
    end

    # Check if fragment is empty
    def empty?
      @content.empty?
    end

    # Append another fragment to this one
    def append(other)
      if other.is_a?(Fragment)
        Fragment.new(@content + other.content)
      else
        Fragment.new(@content + [other])
      end
    end

    # Cut this fragment to a range
    def cut(from = 0, to = nil)
      to ||= size

      return Fragment.new([]) if from >= to

      cut_nodes(from, to)
    end

    def cut_nodes(from, to)
      result = []
      pos = 0

      @content.each do |node|
        node_end = pos + node.node_size

        result << node if in_range_before_from?(pos, node_end, from)
        result << node if overlaps_range?(pos, node_end, from, to)

        pos = node_end
        break if pos >= to
      end

      Fragment.new(result)
    end

    def in_range_before_from?(_pos, node_end, from)
      node_end <= from
    end

    def overlaps_range?(pos, node_end, from, to)
      (pos >= from && node_end <= to) || (pos < from && node_end > from)
    end

    # Replace child at index
    def replace_child(index, replacement)
      new_content = @content.dup
      new_content[index] = replacement
      Fragment.new(new_content)
    end

    # Iterate over all nodes between positions
    def nodes_between(from, to, callback = nil, node_start = 0, &blk)
      cb = callback || blk
      return unless cb && to > from

      pos = 0

      @content.each do |node|
        node_end = pos + node.node_size
        next unless node_end > from

        dispatch_node_callback(node, pos, node_end, from, to, cb, node_start)
        pos = node_end
        break if pos >= to
      end
    end

    def dispatch_node_callback(node, pos, node_end, from, to, callback, node_start)
      if node.text?
        text_node_callback(node, pos, from, node_start, callback)
      elsif node_fully_in_range?(pos, node_end, from, to)
        full_node_callback(node, pos, node_end, from, to, callback, node_start)
      elsif node_overlaps_from?(pos, node_end, from)
        partial_node_callback(node, pos, node_end, from, to, callback, node_start)
      end
    end

    def text_node_callback(node, pos, from, node_start, callback)
      callback.call(node, node_start + (from - pos).clamp(0, node.node_size - 1))
    end

    def node_fully_in_range?(pos, node_end, from, to)
      pos >= from && node_end <= to
    end

    def full_node_callback(node, _pos, _node_end, _from, _to, callback, node_start)
      callback.call(node, node_start)
      recurse_into_node(node, 0, node.content.size, callback, node_start)
    end

    def partial_node_callback(node, pos, _node_end, from, to, callback, node_start)
      recurse_into_node(node, from - pos, [to - pos, node.content.size].min, callback, node_start)
    end

    def node_overlaps_from?(pos, node_end, from)
      pos < from && node_end > from
    end

    def recurse_into_node(node, start_pos, end_pos, callback, node_start)
      return unless node.respond_to?(:nodes_between)

      node.nodes_between(start_pos, end_pos, callback, node_start)
    end

    # Iterate over all descendant nodes
    def descendants(block, node_start = 0)
      nodes_between(0, size, block, node_start)
    end

    # Extract text content between positions
    def text_between(_from, _to, separator = "", _block_separator = "\n")
      result = []
      @content.each do |node|
        if node.respond_to?(:text)
          result << node.text
        elsif node.respond_to?(:text_content)
          result << node.text_content
        end
      end
      result.join(separator)
    end

    # Find first position where two fragments differ
    def find_diff_start(other)
      min_length = [@content.length, other.content.length].min

      pos = 0
      min_length.times do |i|
        return pos if @content[i] != other.content[i]

        pos += @content[i].node_size
      end

      return nil if @content.length == other.content.length

      pos
    end

    # Find last position where two fragments differ
    def find_diff_end(other)
      my_nodes = @content.reverse
      other_nodes = other.content.reverse

      i = 0
      end_pos = size

      while i < my_nodes.length && i < other_nodes.length
        my_node = my_nodes[i]
        other_node = other_nodes[i]

        unless my_node == other_node
          return end_pos
        end

        end_pos -= my_node.node_size
        i += 1
      end

      nil
    end

    # Check equality
    def eq?(other)
      return false unless other.is_a?(Fragment)

      @content.length == other.content.length &&
        @content.zip(other.content).all? { |a, b| a.to_h == b.to_h }
    end

    alias == eq?

    # Hash for use in sets/hashes
    def hash
      @content.map(&:to_h).hash
    end

    # Access by index
    def [](index)
      @content[index]
    end

    # Iterate
    def each(&block)
      @content.each(&block)
    end

    # Number of items
    def length
      @content.length
    end

    alias count length

    # Convert to array
    def to_a
      @content.dup
    end

    # Create empty fragment
    def self.empty
      @empty ||= new([])
    end

    # Create from content
    def self.from(content)
      case content
      when Fragment then content
      when Array then new(content.flatten)
      else new([content])
      end
    end

    def to_s
      "<Fragment #{@content.length} nodes>"
    end

    def inspect
      to_s
    end
  end
end
