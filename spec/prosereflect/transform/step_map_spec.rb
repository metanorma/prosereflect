# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::StepMap do
  describe "creation" do
    it "creates an empty step map" do
      map = described_class.empty
      expect(map.ranges).to eq([])
    end

    it "creates a delete step map" do
      map = described_class.delete(5, 10)
      expect(map.ranges).to eq([[5, 10, 5, 5]])
    end

    it "creates a replace step map" do
      map = described_class.replace(5, 10, 5, 15)
      expect(map.ranges).to eq([[5, 10, 5, 15]])
    end
  end

  describe "map" do
    it "maps position before any range unchanged" do
      map = described_class.new([[5, 10, 5, 5]])
      expect(map.map(3)).to eq(3)
    end

    it "maps position before range with offset" do
      map = described_class.new([[5, 10, 3, 3]])
      expect(map.map(3)).to eq(1)
    end

    it "maps position inside range" do
      map = described_class.new([[5, 10, 3, 3]])
      expect(map.map(7)).to eq(5)
    end

    it "maps position after range with offset" do
      map = described_class.new([[5, 10, 3, 3]])
      expect(map.map(15)).to eq(8)
    end
  end

  describe "deleted?" do
    it "returns false for position before range" do
      map = described_class.new([[5, 10, 5, 5]])
      expect(map.deleted?(3)).to be false
    end

    it "returns true for position inside range" do
      map = described_class.new([[5, 10, 5, 5]])
      expect(map.deleted?(7)).to be true
    end

    it "returns false for position after range" do
      map = described_class.new([[5, 10, 5, 5]])
      expect(map.deleted?(15)).to be false
    end
  end

  describe "add_map" do
    it "combines two independent maps" do
      map1 = described_class.new([[0, 5, 0, 5]])
      map2 = described_class.new([[10, 15, 10, 15]])
      result = map1.add_map(map2)
      expect(result.ranges.length).to eq(2)
    end
  end
end
