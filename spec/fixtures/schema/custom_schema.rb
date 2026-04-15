# frozen_string_literal: true

require "prosereflect"
require "prosereflect/schema"

# Custom schema with mark exclusion rules
# Used for testing that link excludes emoji
module CustomSchemaFixture
  CUSTOM_SCHEMA_NODES = {
    "doc" => { "content" => "block+" },
    "paragraph" => { "content" => "inline*" },
    "text" => {},
  }.freeze

  CUSTOM_SCHEMA_MARKS = {
    "link" => { "excludes" => "emoji" },
    "bold" => {},
    "italic" => {},
    "emoji" => {},
  }.freeze

  def self.build
    Prosereflect::Schema.new(
      nodes_spec: CUSTOM_SCHEMA_NODES,
      marks_spec: CUSTOM_SCHEMA_MARKS,
      top_node: "doc",
    )
  end

  def self.nodes
    CUSTOM_SCHEMA_NODES
  end

  def self.marks
    CUSTOM_SCHEMA_MARKS
  end
end
