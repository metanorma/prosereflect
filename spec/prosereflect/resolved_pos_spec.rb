# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::ResolvedPos do
  let(:doc) { Prosereflect::Document.new }
  let(:resolved) { doc.resolve(0) }

  describe "creation" do
    it "creates resolved position" do
      expect(resolved).to be_a(described_class)
    end

    it "has position" do
      expect(resolved.pos).to eq(0)
    end
  end

  describe "parent" do
    it "returns parent node" do
      expect(resolved.parent).to be_a(Prosereflect::Document)
    end
  end

  describe "depth" do
    it "returns depth" do
      expect(resolved.depth).to be >= 0
    end
  end

  describe "index" do
    it "returns index within parent" do
      expect(resolved.index).to eq(0)
    end
  end

  describe "start" do
    it "returns start position" do
      expect(resolved.start).to eq(0)
    end
  end

  describe "parent_offset" do
    it "calculates offset within parent" do
      expect(resolved.parent_offset).to eq(0)
    end
  end

  describe "block?" do
    it "checks if at block level" do
      expect(resolved.block?).to be(false)
    end
  end

  describe "inline?" do
    it "checks if at inline level" do
      expect(resolved.inline?).to be(true)
    end
  end

  describe "equality" do
    it "compares equal positions" do
      other = doc.resolve(0)
      expect(resolved).to eq(other)
    end
  end

  describe "shared_depth" do
    it "returns shared depth with another position" do
      other = doc.resolve(0)
      expect(resolved.shared_depth(other)).to be >= 0
    end
  end
end
