# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::Slice do
  let(:content) { Prosereflect::Fragment.new([]) }

  describe "creation" do
    it "creates empty slice" do
      slice = described_class.new(content)
      expect(slice.empty?).to be true
    end

    it "creates slice with open boundaries" do
      slice = described_class.new(content, 1, 1)
      expect(slice.open_start).to eq(1)
      expect(slice.open_end).to eq(1)
    end
  end

  describe "empty?" do
    it "returns true for empty slice" do
      expect(described_class.empty.empty?).to be true
    end
  end

  describe "size" do
    it "returns 0 for empty slice" do
      expect(described_class.empty.size).to eq(0)
    end
  end

  describe "cut" do
    it "returns same slice when cutting full range" do
      slice = described_class.new(content)
      result = slice.cut(0, slice.size)
      expect(result.size).to eq(slice.size)
    end
  end

  describe "equality" do
    it "compares equal slices" do
      slice1 = described_class.new(content)
      slice2 = described_class.new(content)
      expect(slice1).to eq(slice2)
    end
  end
end
