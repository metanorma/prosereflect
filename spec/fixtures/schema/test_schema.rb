# frozen_string_literal: true

require "prosereflect"
require "prosereflect/schema"

# Test schema matching prosemirror-py test_schema
# Used for testing content expressions, mark handling, etc.
module TestSchemaFixture
  TEST_SCHEMA_NODES = {
    "doc" => { "content" => "block+" },
    "paragraph" => { "content" => "inline*" },
    "code_block" => { "content" => "text*", "marks" => "" },
    "heading" => { "content" => "inline*", "attrs" => { "level" => { "default" => 1 } } },
    "blockquote" => { "content" => "block+", "defining" => true },
    "horizontal_rule" => {},
    "text" => {},
    "image" => { "attrs" => { "src" => {}, "alt" => { "default" => "" }, "title" => { "default" => "" } } },
    "hard_break" => { "selectable" => false },
    "ordered_list" => { "content" => "list_item+", "attrs" => { "order" => { "default" => 1 } }, "group" => "block" },
    "bullet_list" => { "content" => "list_item+", "group" => "block" },
    "list_item" => { "content" => "paragraph block*", "defining" => true },
  }.freeze

  TEST_SCHEMA_MARKS = {
    "link" => { "attrs" => { "href" => {}, "title" => { "default" => "" } }, "inclusive" => false },
    "em" => {},
    "strong" => {},
    "code" => {},
  }.freeze

  def self.build
    Prosereflect::Schema.new(
      nodes_spec: TEST_SCHEMA_NODES,
      marks_spec: TEST_SCHEMA_MARKS,
      top_node: "doc",
    )
  end

  def self.nodes
    TEST_SCHEMA_NODES
  end

  def self.marks
    TEST_SCHEMA_MARKS
  end
end
