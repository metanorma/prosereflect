# frozen_string_literal: true

require "spec_helper"
require_relative "conftest"

RSpec.describe Prosereflect::Schema::Mark do
  include_context "test_schema"

  # Use test_schema by default
  let(:schema) { test_schema }

  describe ".same_set" do
    it "returns true for identical mark sets" do
      em1 = schema.mark_type("em").create
      em2 = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      expect(described_class.same_set([em1, strong], [em2, strong])).to be true
    end

    it "returns false for different mark sets" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create
      code = schema.mark_type("code").create

      expect(described_class.same_set([em, strong], [em, code])).to be false
    end

    it "returns false for sets of different lengths" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      expect(described_class.same_set([em, strong], [em])).to be false
    end

    it "returns true for empty sets" do
      expect(described_class.same_set([], [])).to be true
    end

    it "compares marks with same type but different attrs" do
      link1 = schema.mark_type("link").create({ "href" => "http://foo" })
      link2 = schema.mark_type("link").create({ "href" => "http://bar" })

      expect(described_class.same_set([link1], [link2])).to be false
    end

    it "compares marks with same type and same attrs" do
      link1 = schema.mark_type("link").create({ "href" => "http://foo" })
      link2 = schema.mark_type("link").create({ "href" => "http://foo" })

      expect(described_class.same_set([link1], [link2])).to be true
    end
  end

  describe "#eq?" do
    it "returns true for marks with same type and attrs" do
      link1 = schema.mark_type("link").create({ "href" => "http://foo" })
      link2 = schema.mark_type("link").create({ "href" => "http://foo" })

      expect(link1.eq?(link2)).to be true
    end

    it "returns false for marks with different attrs" do
      link1 = schema.mark_type("link").create({ "href" => "http://foo" })
      link2 = schema.mark_type("link").create({ "href" => "http://bar" })

      expect(link1.eq?(link2)).to be false
    end

    it "returns false for marks with different types" do
      link = schema.mark_type("link").create({ "href" => "http://foo" })
      em = schema.mark_type("em").create

      expect(link.eq?(em)).to be false
    end

    it "returns true for same object" do
      link = schema.mark_type("link").create({ "href" => "http://foo" })

      expect(link.eq?(link)).to be true
    end
  end

  describe "#add_to_set" do
    it "adds mark to empty set" do
      em = schema.mark_type("em").create

      result = em.add_to_set([])

      expect(result.length).to eq(1)
      expect(result.first.type.name).to eq("em")
    end

    it "returns original set if mark already exists" do
      em = schema.mark_type("em").create
      existing_set = [em]

      result = em.add_to_set(existing_set)

      expect(result).to equal(existing_set)
    end

    it "adds mark to set with other marks of different types" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      result = em.add_to_set([strong])

      expect(result.length).to eq(2)
      expect(result.map { |x| x.type.name }).to include("em", "strong")
    end

    it "adds link mark with different href replacing existing link" do
      link1 = schema.mark_type("link").create({ "href" => "http://foo" })
      link2 = schema.mark_type("link").create({ "href" => "http://bar" })
      em = schema.mark_type("em").create

      result = link2.add_to_set([link1, em])

      # link2 should replace link1, em should remain
      expect(result.length).to eq(2)
      link_result = result.find { |m| m.type.name == "link" }
      expect(link_result.attrs["href"]).to eq("http://bar")
    end

    it "maintains rank ordering" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create
      code = schema.mark_type("code").create

      # Add marks in different order and verify sorting
      result = code.add_to_set([em, strong])

      # Should be sorted by rank (em=0, strong=1, code=2)
      expect(result.map { |x| x.type.name }).to eq(["em", "strong", "code"])
    end
  end

  describe "#remove_from_set" do
    it "removes mark from set" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      result = em.remove_from_set([em, strong])

      expect(result.length).to eq(1)
      expect(result.first.type.name).to eq("strong")
    end

    it "returns unchanged set if mark not present" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create
      code = schema.mark_type("code").create

      result = em.remove_from_set([strong, code])

      expect(result.length).to eq(2)
    end

    it "returns empty set when removing only mark" do
      em = schema.mark_type("em").create

      result = em.remove_from_set([em])

      expect(result).to be_empty
    end
  end

  describe "#is_in_set?" do
    it "returns true when mark is in set" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      expect(em.is_in_set?([em, strong])).to be true
    end

    it "returns false when mark is not in set" do
      em = schema.mark_type("em").create
      strong = schema.mark_type("strong").create

      expect(em.is_in_set?([strong])).to be false
    end
  end

  context "with custom schema exclusion rules" do
    # Custom schema with link excludes emoji
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

    describe ".same_set" do
      it "returns true for identical mark sets" do
        bold1 = schema.mark_type("bold").create
        bold2 = schema.mark_type("bold").create
        italic = schema.mark_type("italic").create

        expect(described_class.same_set([bold1, italic], [bold2, italic])).to be true
      end
    end

    describe "#add_to_set" do
      it "link excludes emoji - emoji removed when link added" do
        # link excludes emoji in this schema
        link = schema.mark_type("link").create({ "href" => "http://example" })
        emoji = schema.mark_type("emoji").create

        result = link.add_to_set([emoji])

        # emoji should be removed because link excludes emoji
        expect(result.map { |x| x.type.name }).not_to include("emoji")
        expect(result.map { |x| x.type.name }).to include("link")
      end

      it "link can be added to empty set" do
        link = schema.mark_type("link").create({ "href" => "http://example" })

        result = link.add_to_set([])

        expect(result.length).to eq(1)
        expect(result.first.type.name).to eq("link")
      end

      it "emoji does not exclude link but link excludes emoji" do
        # emoji has no excludes, but link excludes emoji
        # So when we try to add emoji to [link], it should fail
        # because link excludes emoji
        link = schema.mark_type("link").create({ "href" => "http://example" })
        emoji = schema.mark_type("emoji").create

        result = emoji.add_to_set([link])

        # link already in set, and link excludes emoji, so emoji not added
        expect(result.map { |x| x.type.name }).to eq(["link"])
      end
    end

    describe "bold and italic coexist" do
      it "bold and italic can coexist in a set" do
        bold = schema.mark_type("bold").create
        italic = schema.mark_type("italic").create

        result = bold.add_to_set([italic])

        expect(result.length).to eq(2)
        expect(result.map { |x| x.type.name }).to include("bold", "italic")
      end

      it "italic and bold can coexist in a set" do
        bold = schema.mark_type("bold").create
        italic = schema.mark_type("italic").create

        result = italic.add_to_set([bold])

        expect(result.length).to eq(2)
        expect(result.map { |x| x.type.name }).to include("bold", "italic")
      end
    end
  end
end
