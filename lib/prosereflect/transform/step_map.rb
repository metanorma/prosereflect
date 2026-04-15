# frozen_string_literal: true

module Prosereflect
  module Transform
    # Maps positions through a step.
    # Represents how positions change when a step is applied.
    class StepMap
      attr_reader :ranges # Array of [old_start, old_end, new_start, new_end]

      def initialize(ranges = [])
        @ranges = ranges
      end

      # Map a position through this step map
      # Returns the new position
      def map(pos)
        offset = 0
        @ranges.each do |old_start, old_end, new_start, new_end|
          if pos <= old_start
            return pos + (new_start - old_start)
          elsif pos < old_end
            return new_start + (pos - old_start)
          elsif pos >= old_end
            offset += (new_end - old_end)
          end
        end
        pos + offset
      end

      # Map a position, returning result with deletion information
      def map_result(pos, on_del: nil) # rubocop:disable Lint:UnusedMethodArgument
        new_pos = map(pos)
        deleted = deleted?(pos)
        Result.new(pos: new_pos, deleted: deleted, transformed: new_pos != pos)
      end

      # Check if a position was deleted by this step
      def deleted?(pos)
        @ranges.any? do |old_start, old_end, _new_start, _new_end|
          pos >= old_start && pos < old_end
        end
      end

      # Add another map to this one (composition)
      def add_map(other)
        return StepMap.new(other.ranges.dup) if @ranges.empty?
        return StepMap.new(@ranges.dup) if other.ranges.empty?

        StepMap.new(merge_ranges_arrays(@ranges.dup, other.ranges.dup))
      end

      def merge_ranges_arrays(ranges1, ranges2)
        return ranges1 if ranges2.empty?
        return ranges2 if ranges1.empty?

        head1 = ranges1.first
        head2 = ranges2.first
        merged_head = compute_merged_head(head1, head2, ranges1, ranges2)
        tail = compute_tail(head1, head2, ranges1, ranges2)
        [merged_head] + tail
      end

      def compute_merged_head(head1, head2, _ranges1, _ranges2)
        if head1[1] <= head2[0]
          head1
        elsif head2[1] <= head1[0]
          head2
        else
          merge_ranges(head1, head2)
        end
      end

      def compute_tail(head1, head2, ranges1, ranges2)
        if head1[1] <= head2[0]
          merge_ranges_arrays(ranges1[1..], ranges2)
        elsif head2[1] <= head1[0]
          merge_ranges_arrays(ranges1, ranges2[1..])
        else
          merge_ranges_arrays(ranges1[1..], ranges2[1..])
        end
      end

      # Create an empty step map
      def self.empty
        new
      end

      # Create a step map for a single deletion
      def self.delete(from, to)
        new([[from, to, from, from]])
      end

      # Create a step map for a single replacement
      def self.replace(from, to, target_from, target_to)
        delta = target_to - target_from
        new([[from, to, target_from, target_from + delta]])
      end

      def to_s
        "<StepMap #{@ranges.inspect}>"
      end

      def inspect
        to_s
      end

      # Result of mapping a position
      Result = Struct.new(:pos, :deleted, :transformed, keyword_init: true) do
        def initialize(pos: 0, deleted: false, transformed: false)
          super
        end
      end

      private

      def merge_ranges(range1, range2)
        [
          [range1[0], range2[0]].min,
          [range1[1], range2[1]].max,
          [range1[2], range2[2]].min,
          [range1[3], range2[3]].max,
        ]
      end
    end
  end
end
