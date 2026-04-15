# frozen_string_literal: true

require "spec_helper"
require_relative "conftest"

RSpec.describe Prosereflect::Schema::ContentMatch do
  include_context "test_schema"

  def get(expression)
    described_class.parse(expression, schema.nodes)
  end

  def match(expression, types)
    m = get(expression)
    ts = types.split.map { |t| schema.nodes[t] }
    i = 0
    while m && i < ts.length
      m = m.match_type(ts[i])
      i += 1
    end
    m ? m.valid_end : false
  end

  describe "parsing content expressions" do
    it "parses empty expression" do
      expect(get("").valid_end).to be true
    end

    it "parses 'image*' with no content" do
      expect(match("image*", "")).to be true
    end

    it "parses 'image*' with image" do
      expect(match("image*", "image")).to be true
    end

    it "parses 'image*' with multiple images" do
      expect(match("image*", "image image image image")).to be true
    end

    it "rejects 'image*' with image and text" do
      expect(match("image*", "image text")).to be false
    end

    it "parses 'inline*' with inline content" do
      expect(match("inline*", "image text")).to be true
    end

    it "rejects 'inline*' with paragraph" do
      expect(match("inline*", "paragraph")).to be false
    end
  end

  describe "choice expressions" do
    it "parses '(paragraph | heading)' with paragraph" do
      expect(match("(paragraph | heading)", "paragraph")).to be true
    end

    it "parses '(paragraph | heading)' with heading" do
      expect(match("(paragraph | heading)", "heading")).to be true
    end

    it "rejects '(paragraph | heading)' with image" do
      expect(match("(paragraph | heading)", "image")).to be false
    end
  end

  describe "sequence expressions" do
    it "parses 'paragraph horizontal_rule paragraph'" do
      expect(match("paragraph horizontal_rule paragraph",
                   "paragraph horizontal_rule paragraph")).to be true
    end

    it "rejects 'paragraph horizontal_rule' when given extra paragraph" do
      expect(match("paragraph horizontal_rule",
                   "paragraph horizontal_rule paragraph")).to be false
    end

    it "rejects 'paragraph horizontal_rule paragraph' when missing final paragraph" do
      expect(match("paragraph horizontal_rule paragraph",
                   "paragraph horizontal_rule")).to be false
    end

    it "rejects when order doesn't match" do
      expect(match("paragraph horizontal_rule",
                   "horizontal_rule paragraph horizontal_rule")).to be false
    end
  end

  describe "optional expressions (*)" do
    it "parses 'heading paragraph*' with just heading" do
      expect(match("heading paragraph*", "heading")).to be true
    end

    it "parses 'heading paragraph*' with multiple paragraphs" do
      expect(match("heading paragraph*",
                   "heading paragraph paragraph")).to be true
    end

    it "parses 'paragraph paragraph*' with paragraph" do
      expect(match("paragraph paragraph*", "paragraph")).to be true
    end
  end

  describe "required expressions (+)" do
    it "parses 'heading paragraph+' with heading and paragraph" do
      expect(match("heading paragraph+", "heading paragraph")).to be true
    end

    it "parses 'heading paragraph+' with multiple paragraphs" do
      expect(match("heading paragraph+",
                   "heading paragraph paragraph")).to be true
    end

    it "rejects 'heading paragraph+' with only heading" do
      expect(match("heading paragraph+", "heading")).to be false
    end

    it "rejects 'paragraph paragraph+' when first is not paragraph" do
      expect(match("paragraph paragraph+",
                   "horizontal_rule paragraph")).to be false
    end
  end

  describe "optional single (?)" do
    it "parses 'image?' with image" do
      expect(match("image?", "image")).to be true
    end

    it "parses 'image?' with empty" do
      expect(match("image?", "")).to be true
    end

    it "rejects 'image?' with multiple images" do
      expect(match("image?", "image image")).to be false
    end
  end

  describe "repeated choice with +" do
    it "parses '(heading paragraph+)+' correctly" do
      expect(match("(heading paragraph+)+",
                   "heading paragraph heading paragraph paragraph")).to be true
    end

    it "rejects when extra content at end" do
      expect(match("(heading paragraph+)+",
                   "heading paragraph heading paragraph paragraph horizontal_rule")).to be false
    end
  end

  describe "range expressions" do
    it "parses 'hard_break{2}' with two breaks" do
      expect(match("hard_break{2}", "hard_break hard_break")).to be true
    end

    it "rejects 'hard_break{2}' with only one" do
      expect(match("hard_break{2}", "hard_break")).to be false
    end

    it "rejects 'hard_break{2}' with three" do
      expect(match("hard_break{2}",
                   "hard_break hard_break hard_break")).to be false
    end

    it "parses 'hard_break{2,4}' with 2-4 breaks" do
      expect(match("hard_break{2,4}", "hard_break hard_break")).to be true
      expect(match("hard_break{2,4}",
                   "hard_break hard_break hard_break")).to be true
      expect(match("hard_break{2,4}",
                   "hard_break hard_break hard_break hard_break")).to be true
    end

    it "rejects 'hard_break{2,4}' with too few" do
      expect(match("hard_break{2,4}", "hard_break")).to be false
    end

    it "rejects 'hard_break{2,4}' with too many" do
      expect(match("hard_break{2,4}",
                   "hard_break hard_break hard_break hard_break hard_break")).to be false
    end

    it "parses 'hard_break{2,}' (unbounded)" do
      expect(match("hard_break{2,}", "hard_break hard_break")).to be true
      expect(match("hard_break{2,}",
                   "hard_break hard_break hard_break hard_break")).to be true
    end

    it "rejects 'hard_break{2,}' with only one" do
      expect(match("hard_break{2,}", "hard_break")).to be false
    end
  end

  describe "mixed expressions" do
    it "parses 'hard_break{2,4} text*'" do
      expect(match("hard_break{2,4} text*", "hard_break hard_break")).to be true
      expect(match("hard_break{2,4} text*",
                   "hard_break hard_break text text")).to be true
    end

    it "rejects 'hard_break{2,4} text*' with invalid content" do
      expect(match("hard_break{2,4} text*",
                   "hard_break hard_break image")).to be false
    end

    it "parses 'hard_break{2,4} image?'" do
      expect(match("hard_break{2,4} image?",
                   "hard_break hard_break image")).to be true
      expect(match("hard_break{2,4} image?",
                   "hard_break hard_break")).to be true
    end
  end

  describe "edge_count" do
    it "returns number of edges" do
      m = get("paragraph | heading")
      expect(m.edge_count).to eq(2)
    end

    it "returns 0 for empty match" do
      m = get("")
      expect(m.edge_count).to eq(0)
    end
  end

  describe "edge" do
    it "returns edge at index" do
      m = get("paragraph | heading")
      expect(m.edge(0).type.name).to eq("paragraph")
      expect(m.edge(1).type.name).to eq("heading")
    end

    it "raises error for out of bounds index" do
      m = get("paragraph")
      expect { m.edge(1) }.to raise_error(Prosereflect::Schema::ContentMatchError)
    end
  end
end
