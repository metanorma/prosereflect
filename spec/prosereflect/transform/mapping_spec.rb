# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::Mapping do
  let(:step_map) { Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]]) }

  describe "creation" do
    it "creates empty mapping" do
      mapping = described_class.new
      expect(mapping.to_a).to eq([])
    end

    it "creates mapping with step maps" do
      mapping = described_class.new(maps: [step_map])
      expect(mapping.to_a.length).to eq(1)
    end
  end

  describe "add_map" do
    it "adds step map to end" do
      mapping = described_class.new
      mapping.add_map(step_map)
      expect(mapping.to_a.length).to eq(1)
    end

    it "adds step map at specific index" do
      mapping = described_class.new(maps: [step_map])
      new_map = Prosereflect::Transform::StepMap.new([[10, 15, 10, 15]])
      mapping.add_map(new_map, 0)
      expect(mapping.to_a.length).to eq(2)
    end
  end

  describe "map" do
    it "maps position through empty mapping returns same position" do
      mapping = described_class.new
      expect(mapping.map(5)).to eq(5)
    end

    it "maps position through single step map" do
      # StepMap [[0, 5, 0, 5]] means: old 0-5 maps to new 0-5 (no change)
      step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
      mapping = described_class.new(maps: [step_map])
      expect(mapping.map(3)).to eq(3)
    end

    it "maps position through multiple step maps" do
      # First step: positions 0-5 stay at 0-5
      # Second step: positions 5-10 stay at 5-5 (5 chars inserted)
      map1 = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
      map2 = Prosereflect::Transform::StepMap.new([[5, 10, 5, 5]])
      mapping = described_class.new(maps: [map1, map2])
      expect(mapping.map(3)).to eq(3)
    end

    it "handles deletion step map" do
      # StepMap [[0, 3, 0, 0]] means: old 0-3 maps to new 0-0 (3 deleted)
      step_map = Prosereflect::Transform::StepMap.new([[0, 3, 0, 0]])
      mapping = described_class.new(maps: [step_map])
      # Position 5 (after deletion) should be offset by -3
      expect(mapping.map(5)).to eq(2)
    end
  end

  describe "map_result" do
    it "returns pos and deleted status for position not deleted" do
      # StepMap [[0, 2, 0, 2]] deletes 0-1, position 5 is after range
      step_map = Prosereflect::Transform::StepMap.new([[0, 2, 0, 2]])
      mapping = described_class.new(maps: [step_map])
      result = mapping.map_result(5)
      expect(result[:pos]).to eq(5)
      expect(result[:deleted]).to be false
    end

    it "returns deleted true for position in deleted range" do
      # StepMap [[0, 3, 0, 0]] means: old 0-3 maps to new 0-0 (3 deleted)
      step_map = Prosereflect::Transform::StepMap.new([[0, 3, 0, 0]])
      mapping = described_class.new(maps: [step_map])
      result = mapping.map_result(1)
      expect(result[:deleted]).to be true
    end
  end

  describe "map_deletes" do
    it "returns false when position not deleted" do
      mapping = described_class.new(maps: [step_map])
      expect(mapping.map_deletes(10)).to be false
    end

    it "returns true when position deleted" do
      # StepMap [[0, 5, 0, 0]] is a deletion of 0-5
      step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 0]])
      mapping = described_class.new(maps: [step_map])
      expect(mapping.map_deletes(2)).to be true
    end

    it "returns false for position after deleted range" do
      # StepMap [[0, 3, 0, 0]] deletes 0-3
      step_map = Prosereflect::Transform::StepMap.new([[0, 3, 0, 0]])
      mapping = described_class.new(maps: [step_map])
      # Position 5 is after the deleted range
      expect(mapping.map_deletes(5)).to be false
    end
  end

  describe "to_a" do
    it "returns array of step maps" do
      mapping = described_class.new(maps: [step_map])
      expect(mapping.to_a).to eq([step_map])
    end
  end

  describe "from_step_map" do
    it "creates mapping from single step map" do
      mapping = described_class.from_step_map(step_map)
      expect(mapping.to_a).to eq([step_map])
    end
  end

  context "with StepMap" do
    describe "creation" do
      it "creates empty step map" do
        step_map = Prosereflect::Transform::StepMap.new
        expect(step_map.ranges).to eq([])
      end

      it "creates step map with ranges" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
        expect(step_map.ranges).to eq([[0, 5, 0, 5]])
      end
    end

    describe ".empty" do
      it "returns empty step map" do
        step_map = Prosereflect::Transform::StepMap.empty
        expect(step_map.ranges).to eq([])
      end
    end

    describe ".delete" do
      it "creates step map for deletion" do
        step_map = Prosereflect::Transform::StepMap.delete(2, 5)
        # [[2, 5, 2, 2]] - from 2 to 5 deleted, maps to position 2
        expect(step_map.ranges).to eq([[2, 5, 2, 2]])
      end
    end

    describe ".replace" do
      it "creates step map for replacement" do
        step_map = Prosereflect::Transform::StepMap.replace(0, 3, 0, 5)
        # [[0, 3, 0, 5]] - old 0-3 replaced with new 0-5
        expect(step_map.ranges).to eq([[0, 3, 0, 5]])
      end
    end

    describe "map" do
      it "maps position before any range unchanged" do
        step_map = Prosereflect::Transform::StepMap.new([[5, 10, 5, 10]])
        expect(step_map.map(3)).to eq(3)
      end

      it "maps position within range" do
        step_map = Prosereflect::Transform::StepMap.new([[2, 5, 2, 8]])
        # Position 3 within old 2-5 maps to 2 + (3-2) = 3
        expect(step_map.map(3)).to eq(3)
      end

      it "maps position after range with offset" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 3, 0, 0]])
        # Position 5 is after deleted range 0-3
        # offset = (0 - 3) = -3
        expect(step_map.map(5)).to eq(2)
      end
    end

    describe "map_result" do
      it "returns result with deleted false when not deleted" do
        # StepMap [[0, 2, 0, 2]] deletes 0-1, position 5 is not in range
        step_map = Prosereflect::Transform::StepMap.new([[0, 2, 0, 2]])
        result = step_map.map_result(5)
        expect(result.deleted).to be false
        expect(result.pos).to eq(5)
      end

      it "returns result with deleted true when in range" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 0]])
        result = step_map.map_result(2)
        expect(result.deleted).to be true
      end
    end

    describe "deleted?" do
      it "returns true for position in deleted range" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 0]])
        expect(step_map.deleted?(2)).to be true
      end

      it "returns false for position after range" do
        step_map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 0]])
        expect(step_map.deleted?(10)).to be false
      end

      it "returns false for position before range" do
        step_map = Prosereflect::Transform::StepMap.new([[5, 10, 5, 10]])
        expect(step_map.deleted?(2)).to be false
      end
    end

    describe "add_map" do
      it "returns other map when self is empty" do
        empty = Prosereflect::Transform::StepMap.new
        other = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
        result = empty.add_map(other)
        expect(result.ranges).to eq([[0, 5, 0, 5]])
      end

      it "returns self when other is empty" do
        map = Prosereflect::Transform::StepMap.new([[0, 5, 0, 5]])
        empty = Prosereflect::Transform::StepMap.new
        result = map.add_map(empty)
        expect(result.ranges).to eq([[0, 5, 0, 5]])
      end
    end
  end
end
