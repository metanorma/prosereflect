# frozen_string_literal: true

require_relative "step_map"

module Prosereflect
  module Transform
    # Tracks position changes through a series of steps.
    # Maps positions forward through the transformation.
    class Mapping
      attr_reader :maps
      attr_accessor :from, :to

      def initialize(maps: [])
        @maps = maps.dup
        @from = 0
        @to = maps.length
      end

      # Add a step map to this mapping
      def add_map(step_map, index = nil)
        if index
          @maps.insert(index, step_map)
        else
          @maps << step_map
        end
        @to = @maps.length
      end

      # Map a position through all steps in this mapping
      def map(pos, on_del: nil) # rubocop:disable Lint:UnusedMethodArgument
        @maps.each do |step_map|
          pos = step_map.map(pos)
        end
        pos
      end

      # Map a position with deletion tracking
      def map_result(pos, on_del: nil)
        deleted = false
        @maps.each do |step_map|
          result = step_map.map_result(pos, on_del: on_del)
          deleted ||= result.deleted
          pos = result.pos
        end
        { pos: pos, deleted: deleted }
      end

      # Map a position backwards through the mapping
      def map_reverse(pos)
        result = pos
        (0...@maps.length).each do |i|
          step_map = @maps[@maps.length - 1 - i]
          result = step_map.map_reverse(result)
        end
        result
      end

      # Check if a position was deleted
      def map_deletes(pos)
        @maps.any? { |step_map| step_map.deleted?(pos) }
      end

      # Get the mapping as an array of step maps
      def to_a
        @maps.dup
      end

      # Create from a single step map
      def self.from_step_map(step_map)
        new(maps: [step_map])
      end

      def to_s
        "<Mapping maps=#{@maps.length}>"
      end

      def inspect
        to_s
      end
    end
  end
end
