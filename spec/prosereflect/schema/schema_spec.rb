# frozen_string_literal: true

require "spec_helper"
require_relative "conftest"

RSpec.describe Prosereflect::Schema do
  include_context "test_schema"

  describe "initialization" do
    it "creates a schema with nodes and marks" do
      expect(schema.nodes).to be_a(Hash)
      expect(schema.marks).to be_a(Hash)
      expect(schema.nodes.keys).to include("doc", "paragraph", "text")
      expect(schema.marks.keys).to include("em", "strong", "link")
    end

    it "raises error for missing top node" do
      expect do
        described_class.new(
          nodes_spec: { "text" => {} },
          marks_spec: {},
        )
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /missing its top node/)
    end

    it "raises error for missing text type" do
      expect do
        described_class.new(
          nodes_spec: { "doc" => { content: "block+" } },
          marks_spec: {},
        )
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /every schema needs a 'text' type/)
    end

    it "raises error if text has attrs" do
      expect do
        described_class.new(
          nodes_spec: {
            "doc" => { content: "block+" },
            "text" => { attrs: { "something" => {} } },
          },
          marks_spec: {},
        )
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /text node type should not have attributes/)
    end

    it "raises error if node and mark share same name" do
      expect do
        described_class.new(
          nodes_spec: {
            "doc" => { content: "block+" },
            "text" => {},
            "bold" => {},
          },
          marks_spec: {
            "bold" => {},
          },
        )
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /can not be both a node and a mark/)
    end
  end

  describe "node_type" do
    it "returns node type by name" do
      node_type = schema.node_type("paragraph")
      expect(node_type.name).to eq("paragraph")
    end

    it "raises error for unknown node type" do
      expect do
        schema.node_type("unknown")
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /Unknown node type/)
    end
  end

  describe "mark_type" do
    it "returns mark type by name" do
      mark_type = schema.mark_type("em")
      expect(mark_type.name).to eq("em")
    end

    it "raises error for unknown mark type" do
      expect do
        schema.mark_type("unknown")
      end.to raise_error(Prosereflect::Schema::ValidationError,
                         /Unknown mark type/)
    end
  end

  describe "node" do
    it "creates a node by type name" do
      node = schema.node("paragraph")
      expect(node.type.name).to eq("paragraph")
    end

    it "creates a node with attrs" do
      node = schema.node("heading", { "level" => 2 })
      expect(node.attrs["level"]).to eq(2)
    end

    it "creates a node with content" do
      text = schema.text("Hello")
      para = schema.node("paragraph", nil, [text])
      expect(para.content.content.first.text).to eq("Hello")
    end

    it "validates content" do
      text = schema.text("Hello")
      expect do
        # doc requires block+, not inline content directly
        schema.node("doc", nil, [text])
      end.to raise_error(Prosereflect::Schema::ValidationError)
    end
  end

  describe "text" do
    it "creates a text node" do
      text_node = schema.text("Hello")
      expect(text_node.text).to eq("Hello")
      expect(text_node.type.name).to eq("text")
    end

    it "creates text with marks" do
      em = schema.mark("em")
      text_node = schema.text("Hello", [em])
      expect(text_node.marks.length).to eq(1)
    end
  end

  describe "mark" do
    it "creates a mark by name" do
      mark = schema.mark("em")
      expect(mark.type.name).to eq("em")
    end

    it "creates a mark with attrs" do
      mark = schema.mark("link", { "href" => "http://example.com" })
      expect(mark.attrs["href"]).to eq("http://example.com")
    end
  end

  describe "node_from_json" do
    it "deserializes a node from JSON" do
      json = {
        "type" => "paragraph",
        "content" => [
          { "type" => "text", "text" => "Hello" },
        ],
      }

      node = schema.node_from_json(json)
      expect(node.type.name).to eq("paragraph")
      expect(node.content.content.first.text).to eq("Hello")
    end

    it "deserializes marks" do
      json = {
        "type" => "paragraph",
        "content" => [
          { "type" => "text", "text" => "Hello",
            "marks" => [{ "type" => "em" }] },
        ],
      }

      node = schema.node_from_json(json)
      expect(node.content.content.first.marks.length).to eq(1)
    end
  end

  describe "mark_from_json" do
    it "deserializes a mark from JSON" do
      json = { "type" => "em" }
      mark = schema.mark_from_json(json)
      expect(mark.type.name).to eq("em")
    end

    it "deserializes mark with attrs" do
      json = { "type" => "link", "attrs" => { "href" => "http://example.com" } }
      mark = schema.mark_from_json(json)
      expect(mark.attrs["href"]).to eq("http://example.com")
    end
  end

  describe "top_node_type" do
    it "returns the top node type" do
      expect(schema.top_node_type.name).to eq("doc")
    end
  end
end
