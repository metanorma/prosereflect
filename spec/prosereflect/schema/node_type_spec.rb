# frozen_string_literal: true

require "spec_helper"
require_relative "conftest"

RSpec.describe Prosereflect::Schema::NodeType do
  include_context "test_schema"

  describe "is_block?" do
    it "returns true for block nodes" do
      expect(schema.node_type("paragraph").is_block?).to be true
      expect(schema.node_type("heading").is_block?).to be true
      expect(schema.node_type("blockquote").is_block?).to be true
    end

    it "returns false for inline nodes" do
      expect(schema.node_type("text").is_block?).to be false
    end
  end

  describe "is_inline?" do
    it "returns true for inline nodes" do
      expect(schema.node_type("text").is_inline?).to be true
    end

    it "returns false for block nodes" do
      expect(schema.node_type("paragraph").is_inline?).to be false
    end
  end

  describe "text?" do
    it "returns true only for text type" do
      expect(schema.node_type("text").text?).to be true
      expect(schema.node_type("paragraph").text?).to be false
    end
  end

  describe "is_leaf?" do
    it "returns true for nodes with empty content expression" do
      expect(schema.node_type("text").is_leaf?).to be true
      expect(schema.node_type("hard_break").is_leaf?).to be true
      expect(schema.node_type("image").is_leaf?).to be true
    end

    it "returns false for nodes with content" do
      expect(schema.node_type("paragraph").is_leaf?).to be false
    end
  end

  describe "has_required_attrs?" do
    it "returns true when node has required attributes" do
      expect(schema.node_type("image").has_required_attrs?).to be true
    end

    it "returns false when all attrs have defaults" do
      expect(schema.node_type("heading").has_required_attrs?).to be false
    end
  end

  describe "default_attrs" do
    it "returns defaults for all attrs" do
      defaults = schema.node_type("heading").default_attrs
      expect(defaults).to eq({ "level" => 1 })
    end

    it "returns nil if any required attr has no default" do
      defaults = schema.node_type("image").default_attrs
      expect(defaults).to be_nil
    end
  end

  describe "compute_attrs" do
    it "uses defaults when attrs not provided" do
      attrs = schema.node_type("heading").compute_attrs(nil)
      expect(attrs).to eq({ "level" => 1 })
    end

    it "overrides defaults with provided values" do
      attrs = schema.node_type("heading").compute_attrs({ "level" => 3 })
      expect(attrs).to eq({ "level" => 3 })
    end

    it "raises error for missing required attrs" do
      expect do
        schema.node_type("image").compute_attrs({})
      end.to raise_error(Prosereflect::Schema::ValidationError)
    end
  end

  describe "create" do
    it "creates a node with computed attrs" do
      node = schema.node_type("heading").create({ "level" => 2 }, nil, [])
      expect(node.attrs["level"]).to eq(2)
    end

    it "raises error for text node" do
      expect do
        schema.node_type("text").create({}, nil, [])
      end.to raise_error(Prosereflect::Schema::Error)
    end
  end

  describe "valid_content?" do
    it "returns true for valid content" do
      frag = Prosereflect::Schema::Fragment.new([
                                                  schema.node_type("paragraph").create(
                                                    nil, [], []
                                                  ),
                                                ])
      expect(schema.node_type("doc").valid_content?(frag)).to be true
    end

    it "returns false for invalid content" do
      frag = Prosereflect::Schema::Fragment.new([
                                                  schema.text(""),
                                                ])
      expect(schema.node_type("doc").valid_content?(frag)).to be false
    end
  end

  describe "check_content" do
    it "raises error for invalid content" do
      frag = Prosereflect::Schema::Fragment.new([
                                                  schema.text(""),
                                                ])
      expect do
        schema.node_type("doc").check_content(frag)
      end.to raise_error(Prosereflect::Schema::ValidationError)
    end
  end

  describe "allows_mark_type?" do
    it "returns true when mark is in mark_set" do
      expect(schema.node_type("paragraph").allows_mark_type?(schema.mark_type("em"))).to be true
      expect(schema.node_type("paragraph").allows_mark_type?(schema.mark_type("strong"))).to be true
    end

    it "returns false when mark is not in mark_set" do
      expect(schema.node_type("code_block").allows_mark_type?(schema.mark_type("em"))).to be false
    end
  end
end
