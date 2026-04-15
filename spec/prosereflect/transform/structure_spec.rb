# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::Structure do
  let(:doc) do
    Prosereflect::Parser.parse_document({
                                          "type" => "doc",
                                          "content" => [
                                            {
                                              "type" => "paragraph",
                                              "content" => [
                                                { "type" => "text", "text" => "Hello" },
                                              ],
                                            },
                                            {
                                              "type" => "paragraph",
                                              "content" => [
                                                { "type" => "text", "text" => "World" },
                                              ],
                                            },
                                          ],
                                        })
  end

  describe ".can_split?" do
    it "returns false for negative position" do
      expect(described_class.can_split?(doc, -1)).to be false
    end

    it "returns false for position beyond document" do
      expect(described_class.can_split?(doc, 999)).to be false
    end

    it "returns true for valid position" do
      expect(described_class.can_split?(doc, 1)).to be true
    end

    it "returns true for position 0" do
      expect(described_class.can_split?(doc, 0)).to be true
    end
  end

  describe ".can_join?" do
    it "returns false for position 0" do
      expect(described_class.can_join?(doc, 0)).to be false
    end

    it "returns false for position at end" do
      expect(described_class.can_join?(doc, doc.node_size)).to be false
    end

    it "returns true for position between paragraphs" do
      # Position 8 is between the two paragraphs (after "Hello" para, before "World" para)
      expect(described_class.can_join?(doc, 8)).to be true
    end
  end

  describe ".join_point?" do
    it "returns nil for position at start" do
      expect(described_class.join_point?(doc, 0)).to be false
    end

    it "returns nil at position within a paragraph" do
      expect(described_class.join_point?(doc, 3)).to be false
    end
  end

  describe ".lift_target" do
    it "returns 0 for empty fragment" do
      fragment = Prosereflect::Fragment.new([])
      result = described_class.lift_target(fragment, 0, 5)
      expect(result).to eq(0)
    end

    it "returns 0 for fragment with no defining nodes" do
      text = Prosereflect::Text.new(text: "hello")
      fragment = Prosereflect::Fragment.new([text])
      result = described_class.lift_target(fragment, 0, 6)
      expect(result).to eq(0)
    end
  end

  describe ".find_wrapping" do
    it "returns empty array for empty fragment" do
      fragment = Prosereflect::Fragment.new([])
      wrappers = described_class.find_wrapping(fragment, 0, 5, "paragraph")
      expect(wrappers).to be_a(Array)
    end

    it "returns empty array for fragment with no defining nodes" do
      text = Prosereflect::Text.new(text: "hello")
      fragment = Prosereflect::Fragment.new([text])
      wrappers = described_class.find_wrapping(fragment, 0, 6, "paragraph")
      expect(wrappers).to eq([])
    end
  end
end
