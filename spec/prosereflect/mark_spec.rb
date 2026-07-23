# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Mark do
  describe ".from_h" do
    it "reconstructs a known mark subclass by type" do
      mark = described_class.from_h({ "type" => "bold" })
      expect(mark).to be_a(Prosereflect::Mark::Bold)
      expect(mark.type).to eq("bold")
    end

    it "carries attrs onto the mark" do
      mark = described_class.from_h({ "type" => "link", "attrs" => { "href" => "https://x" } })
      expect(mark).to be_a(Prosereflect::Mark::Link)
      expect(mark.attrs).to eq({ "href" => "https://x" })
    end

    it "falls back to Base for an unknown type" do
      mark = described_class.from_h({ "type" => "blink" })
      expect(mark).to be_a(Prosereflect::Mark::Base)
      expect(mark.type).to eq("blink")
    end

    it "does not resolve an unrelated Ruby constant, falling back to Base" do
      mark = described_class.from_h({ "type" => "string" })
      expect(mark).to be_a(Prosereflect::Mark::Base)
      expect(mark.type).to eq("string")
    end

    it "accepts symbol keys" do
      mark = described_class.from_h({ type: "italic" })
      expect(mark).to be_a(Prosereflect::Mark::Italic)
    end
  end

  describe "runtime mark-set operations" do
    let(:bold) { Prosereflect::Mark::Bold.new }
    let(:italic) { Prosereflect::Mark::Italic.new }
    let(:link_a) { Prosereflect::Mark::Link.new(attrs: { "href" => "a" }) }
    let(:link_b) { Prosereflect::Mark::Link.new(attrs: { "href" => "b" }) }

    describe "#add_to_set" do
      it "appends a new mark" do
        expect(bold.add_to_set([italic]).map(&:type)).to eq(%w[italic bold])
      end

      it "replaces a same-type mark (re-adding a link with a new href)" do
        result = link_b.add_to_set([link_a, bold])
        expect(result.map(&:type)).to eq(%w[bold link])
        expect(result.last.attrs).to eq({ "href" => "b" })
      end

      it "does not mutate the input set" do
        set = [italic]
        bold.add_to_set(set)
        expect(set.map(&:type)).to eq(%w[italic])
      end
    end

    describe "#remove_from_set" do
      it "removes an exact match" do
        expect(bold.remove_from_set([bold, italic]).map(&:type)).to eq(%w[italic])
      end

      it "leaves a same-type mark with different attrs in place" do
        result = link_a.remove_from_set([link_a, link_b])
        expect(result.map(&:attrs)).to eq([{ "href" => "b" }])
      end
    end
  end
end
