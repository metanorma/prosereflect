# frozen_string_literal: true

require_relative "transform/step_map"
require_relative "transform/mapping"
require_relative "transform/slice"
require_relative "transform/step"
require_relative "transform/replace_step"
require_relative "transform/mark_step"
require_relative "transform/attr_step"
require_relative "transform/insert_step"
require_relative "transform/structure"
require_relative "transform/transform"

module Prosereflect
  # Transform system for chainable document transformations
  # Based on ProseMirror's transform/step system
  module Transform
    class Error < StandardError; end

    # Raised when a step cannot be applied to a document
    class ApplyError < Error; end

    # Raised when a step cannot be inverted
    class InvertError < Error; end
  end
end
