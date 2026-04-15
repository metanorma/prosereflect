# frozen_string_literal: true

require_relative "step_map"
require_relative "mapping"

module Prosereflect
  module Transform
    # Base class for all document transformations.
    # A step represents an atomic document change.
    class Step
      # Apply this step to a document
      # Returns a Result with the new document or an error
      def apply(_doc)
        raise NotImplementedError, "#{self.class} must implement #apply"
      end

      # Get the step map for position tracking
      def get_map
        raise NotImplementedError, "#{self.class} must implement #get_map"
      end

      # Merge this step with another if possible
      # Returns a new step or nil if not mergeable
      def merge(_other)
        nil
      end

      # Return an inverted step that undoes this one
      # Takes the document as input to compute the inverse
      def invert(_doc)
        raise NotImplementedError, "#{self.class} must implement #invert"
      end

      # Get a JSON representation
      def to_json(*_args)
        {
          "stepType" => step_type,
          "pos" => pos,
          "to" => to,
        }.compact
      end

      # Create a step from JSON
      def self.from_json(_schema, _json)
        raise NotImplementedError, "#{self.class} must implement #from_json"
      end

      # The type name of this step
      def step_type
        raise NotImplementedError, "#{self.class} must implement #step_type"
      end

      # Position where this step applies
      def pos
        0
      end

      # End position (for range steps)
      def to
        pos
      end

      # Result of applying a step
      class Result
        attr_reader :doc, :failed

        def initialize(doc: nil, failed: nil)
          @doc = doc
          @failed = failed
        end

        # Check if the step was successfully applied
        def ok?
          !@failed && @doc
        end

        # Create a successful result
        def self.ok(doc)
          new(doc: doc)
        end

        # Create a failed result
        def self.fail(reason)
          new(failed: reason)
        end
      end
    end
  end
end
