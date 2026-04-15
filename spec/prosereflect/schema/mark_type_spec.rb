# frozen_string_literal: true

require "spec_helper"
require_relative "conftest"

RSpec.describe Prosereflect::Schema::MarkType do
  include_context "test_schema"

  describe "create" do
    it "creates a mark with attrs" do
      mark = schema.mark_type("link").create({ "href" => "http://example.com" })
      expect(mark.attrs["href"]).to eq("http://example.com")
    end

    it "uses default instance when no attrs provided" do
      mark_type = schema.mark_type("link")
      mark = mark_type.create(nil)
      # The instance should have the default title
      expect(mark.type).to eq(mark_type)
    end
  end

  describe "remove_from_set" do
    it "removes mark from set" do
      mark_type = schema.mark_type("em")
      mark = mark_type.create
      mark_set = [mark]

      result = mark_type.remove_from_set(mark_set)
      expect(result).to be_empty
    end

    it "keeps other marks" do
      em_mark = schema.mark_type("em").create
      strong_mark = schema.mark_type("strong").create
      mark_set = [em_mark, strong_mark]

      result = schema.mark_type("em").remove_from_set(mark_set)
      expect(result).to eq([strong_mark])
    end
  end

  describe "is_in_set?" do
    it "returns true when mark is in set" do
      mark = schema.mark_type("em").create
      mark_set = [mark]

      expect(schema.mark_type("em").is_in_set?(mark_set)).to be true
    end

    it "returns false when mark is not in set" do
      mark = schema.mark_type("em").create
      mark_set = [mark]

      expect(schema.mark_type("strong").is_in_set?(mark_set)).to be false
    end
  end

  describe "excludes?" do
    it "returns false by default" do
      expect(schema.mark_type("em").excludes?(schema.mark_type("strong"))).to be false
    end
  end

  describe "with custom_schema (exclusions)" do
    include_context "custom_schema"

    it "link excludes emoji" do
      expect(custom_schema.mark_type("link").excludes?(custom_schema.mark_type("emoji"))).to be true
    end

    it "emoji does not exclude link" do
      expect(custom_schema.mark_type("emoji").excludes?(custom_schema.mark_type("link"))).to be false
    end
  end

  describe "inclusive?" do
    it "returns false for link (non-inclusive)" do
      expect(schema.mark_type("link").inclusive?).to be false
    end

    it "returns true for em (inclusive by default)" do
      expect(schema.mark_type("em").inclusive?).to be true
    end
  end
end
