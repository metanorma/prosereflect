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

      # Get a JSON representation. Subclasses add their own positions; the base
      # cannot guess them, and guessing produced keys that meant nothing.
      def to_json(*_args)
        { "stepType" => step_type }
      end

      # Create a step from JSON
      def self.from_json(_schema, _json)
        raise NotImplementedError, "#{self.class} must implement #from_json"
      end

      # Read a position out of deserialized JSON, refusing anything that is not
      # an Integer. Positions come from another producer's wire format, so they
      # are checked here rather than surfacing as a NoMethodError inside `apply`.
      def self.integer_position(json, key)
        value = json[key]
        return value if value.is_a?(Integer)

        raise ArgumentError, "#{name}: #{key.inspect} must be an Integer, got #{value.class}"
      end

      # The type name of this step
      def step_type
        raise NotImplementedError, "#{self.class} must implement #step_type"
      end

      # Whether pos can address a node in doc. A step that addresses a node reads
      # a position in 0...node_size, so node_size itself is out of bounds. Range
      # ends and insertion gaps are a different space and may equal node_size.
      # In bounds is not the same as occupied: a position inside a text node's
      # characters passes this and still resolves to no node.
      def position_in_bounds?(pos, doc)
        !pos.negative? && pos < doc.node_size
      end

      private :position_in_bounds?
      private_class_method :integer_position

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
