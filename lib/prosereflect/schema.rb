# frozen_string_literal: true

module Prosereflect
  module SchemaErrors
    class Error < StandardError; end
    class AttributeParseError < Error; end
    class ContentMatchError < Error; end
    class ValidationError < Error; end
  end
end

# Define Schema as a proper class (not module) that will be extended by schema_main.rb
# The nested classes (NodeType, MarkType, etc.) are defined in their own files
# and accessed as Prosereflect::Schema::NodeType etc.
module Prosereflect
  class Schema
    class << self
      attr_accessor :node_types, :mark_types
    end
    self.node_types = []
    self.mark_types = []

    # Alias ContentMatchError for backwards compatibility
    ContentMatchError = Prosereflect::SchemaErrors::ContentMatchError

    # Alias Error for backwards compatibility
    Error = Prosereflect::SchemaErrors::Error
  end
end

require_relative "schema/attribute"
require_relative "schema/spec"
require_relative "schema/fragment"
require_relative "schema/mark"
require_relative "schema/node"
require_relative "schema/content_match"
require_relative "schema/mark_type"
require_relative "schema/node_type"
require_relative "schema/schema_main"
