# frozen_string_literal: true

require "bundler/setup"
require "prosereflect"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

# Standard test schema matching prosemirror-py test_builder
RSpec.shared_context "test_schema" do
  let(:test_schema) do
    Prosereflect::Schema.new(
      nodes_spec: {
        "doc" => { content: "block+" },
        "paragraph" => { content: "inline*", group: "block" },
        "heading" => { content: "inline*",
                       attrs: { "level" => { default: 1 } }, group: "block" },
        "blockquote" => { content: "block+", group: "block" },
        "code_block" => { content: "text*", marks: "", code: true,
                          group: "block" },
        "horizontal_rule" => { group: "block" },
        "text" => { group: "inline" },
        "image" => { inline: true, group: "inline", atom: true,
                     attrs: { "src" => {}, "alt" => { default: "" }, "title" => { default: "" } } },
        "hard_break" => { inline: true, group: "inline", atom: true },
        "ordered_list" => { content: "list_item+", group: "block",
                            attrs: { "order" => { default: 1 } } },
        "bullet_list" => { content: "list_item+", group: "block" },
        "list_item" => { content: "paragraph block*", defining: true },
      },
      marks_spec: {
        "link" => { attrs: { "href" => { default: "" }, "title" => { default: "" } },
                    inclusive: false },
        "em" => { group: "mark" },
        "strong" => { group: "mark" },
        "code" => { group: "mark" },
      },
    )
  end

  let(:schema) { test_schema }
end

RSpec.shared_context "custom_schema" do
  let(:custom_schema) do
    Prosereflect::Schema.new(
      nodes_spec: {
        "doc" => { content: "block+" },
        "paragraph" => { content: "inline*", group: "block" },
        "text" => { group: "inline" },
      },
      marks_spec: {
        "bold" => {},
        "italic" => {},
        "link" => { attrs: { "href" => {} }, inclusive: false,
                    excludes: "emoji" },
        "emoji" => { group: "mark" },
      },
    )
  end

  let(:schema) { custom_schema }
end
