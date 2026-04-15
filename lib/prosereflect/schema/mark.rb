# frozen_string_literal: true

module Prosereflect
  class Schema
    # Lightweight Mark class for schema validation
    class Mark
      attr_reader :type, :attrs

      def initialize(type:, attrs: {})
        @type = type
        @attrs = attrs || {}
      end

      def eq?(other)
        return false unless other.is_a?(Mark)

        @type == other.type && @attrs == other.attrs
      end

      def same_set?(other_marks)
        return false unless other_marks.length == length

        other_marks.each_with_index.all? { |m, i| self[i].eq?(m) }
      end

      def [](index)
        @type.is_a?(Array) ? @type[index] : self
      end

      def length
        1
      end

      def is_in_set?(mark_set)
        mark_set.any? { |m| m.type == @type }
      end

      # Add this mark to a set, respecting exclusion rules and rank ordering
      # Follows prosemirror-py Mark.add_to_set logic
      def add_to_set(mark_set)
        copy = nil
        placed = false

        mark_set.each_with_index do |other, i|
          if eq?(other)
            # Self already in set, return unchanged
            return mark_set
          end

          if @type.excludes?(other.type)
            # This mark's type excludes the other's type
            # Remove the other from the result by starting copy
            copy ||= mark_set[0...i]
          elsif other.type.excludes?(@type)
            # Other's type excludes this mark's type - don't add
            return mark_set
          else
            # No exclusion - insert before if other's rank is higher and not yet placed
            if !placed && other.type.rank > @type.rank
              copy ||= mark_set[0...i]
              copy << self
              placed = true
            end
            copy << other if copy
          end
        end

        copy ||= mark_set.dup
        copy << self unless placed
        sort_marks(copy)
      end

      def remove_from_set(mark_set)
        mark_set.reject { |m| m.type == @type }
      end

      def to_h
        result = { "type" => @type.name }
        result["attrs"] = @attrs unless @attrs.empty?
        result
      end

      def to_s
        "<Mark #{@type.name}>"
      end

      class << self
        def set_from(marks)
          return none if marks.nil? || marks.empty?

          marks.filter_map { |m| m.is_a?(Mark) ? m : m }
        end

        def none
          @none ||= []
        end

        def sort_marks(marks)
          marks.sort_by { |m| m.type.rank }
        end

        # Class method for comparing two mark sets
        # Returns true if both sets contain the same marks in the same order
        def same_set(a, b)
          return true if a == b
          return false unless a.length == b.length

          a.each_with_index.all? do |mark_a, i|
            mark_a.eq?(b[i])
          end
        end
      end

      private

      def sort_marks(marks)
        marks.sort_by { |m| m.type.rank }
      end
    end
  end
end
