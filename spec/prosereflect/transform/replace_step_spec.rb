# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::ReplaceStep do
  describe "creation" do
    it "creates replace step with from, to, and slice" do
      slice = Prosereflect::Transform::Slice.empty
      step = described_class.new(0, 5, slice)
      expect(step.from).to eq(0)
      expect(step.to).to eq(5)
      expect(step.slice).to eq(slice)
    end

    it "creates replace step with default empty slice" do
      step = described_class.new(0, 5)
      expect(step.slice).to eq(Prosereflect::Transform::Slice.empty)
    end
  end

  describe "get_map" do
    it "returns step map for the replacement" do
      step = described_class.new(2, 5, Prosereflect::Transform::Slice.empty)
      step_map = step.get_map
      expect(step_map).to be_a(Prosereflect::Transform::StepMap)
    end
  end

  describe "step_type" do
    it "returns replace" do
      step = described_class.new(0, 5)
      expect(step.step_type).to eq("replace")
    end
  end

  describe "merge" do
    it "merges adjacent empty deletions" do
      # step1: delete 3-4
      step1 = described_class.new(3, 4, Prosereflect::Transform::Slice.empty)
      # step2: delete 4-5 (adjacent - step1's end equals step2's start)
      step2 = described_class.new(4, 5, Prosereflect::Transform::Slice.empty)

      merged = step1.merge(step2)
      expect(merged).not_to be_nil
    end

    it "does not merge overlapping deletions" do
      # step1: delete 1-3
      step1 = described_class.new(1, 3, Prosereflect::Transform::Slice.empty)
      # step2: delete 2-4 (overlaps with step1)
      step2 = described_class.new(2, 4, Prosereflect::Transform::Slice.empty)

      merged = step1.merge(step2)
      expect(merged).to be_nil
    end

    it "merges adjacent deletions extending backward" do
      # step1: delete 3-4
      step1 = described_class.new(3, 4, Prosereflect::Transform::Slice.empty)
      # step2: delete 2-3 (extends backward from step1)
      step2 = described_class.new(2, 3, Prosereflect::Transform::Slice.empty)

      merged = step2.merge(step1)
      expect(merged).not_to be_nil
    end

    it "does not merge far apart steps" do
      step1 = described_class.new(1, 2, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(5, 6, Prosereflect::Transform::Slice.empty)

      merged = step1.merge(step2)
      expect(merged).to be_nil
    end
  end

  describe "can_extend_deletion?" do
    it "returns true when other starts at this end with empty slice" do
      step1 = described_class.new(2, 4, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(4, 6, Prosereflect::Transform::Slice.empty)
      expect(step1.can_extend_deletion?(step2)).to be true
    end

    it "returns false when other does not start at this end" do
      step1 = described_class.new(2, 4, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(5, 7, Prosereflect::Transform::Slice.empty)
      expect(step1.can_extend_deletion?(step2)).to be false
    end

    it "returns false when self.slice is not empty" do
      content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
      step1 = described_class.new(2, 4, Prosereflect::Transform::Slice.new(content))
      step2 = described_class.new(4, 6, Prosereflect::Transform::Slice.empty)
      expect(step1.can_extend_deletion?(step2)).to be false
    end
  end

  describe "can_prepend_deletion?" do
    it "returns true when other ends at this start with empty slice" do
      step1 = described_class.new(4, 6, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(2, 4, Prosereflect::Transform::Slice.empty)
      expect(step1.can_prepend_deletion?(step2)).to be true
    end

    it "returns false when other does not end at this start" do
      step1 = described_class.new(4, 6, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(2, 3, Prosereflect::Transform::Slice.empty)
      expect(step1.can_prepend_deletion?(step2)).to be false
    end
  end

  describe "can_append_content?" do
    it "returns true when other starts at this end with content" do
      step1 = described_class.new(2, 3, Prosereflect::Transform::Slice.empty)
      content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
      step2 = described_class.new(3, 3, Prosereflect::Transform::Slice.new(content))
      expect(step1.can_append_content?(step2)).to be true
    end

    it "returns false when other starts at different position" do
      step1 = described_class.new(2, 3, Prosereflect::Transform::Slice.empty)
      content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
      step2 = described_class.new(4, 4, Prosereflect::Transform::Slice.new(content))
      expect(step1.can_append_content?(step2)).to be false
    end

    it "returns false when other has empty slice" do
      step1 = described_class.new(2, 3, Prosereflect::Transform::Slice.empty)
      step2 = described_class.new(3, 3, Prosereflect::Transform::Slice.empty)
      expect(step1.can_append_content?(step2)).to be false
    end
  end

  describe "can_prepend_content?" do
    it "returns true when other ends at this start with content" do
      content1 = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "y")])
      step1 = described_class.new(3, 3, Prosereflect::Transform::Slice.new(content1))
      content2 = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
      step2 = described_class.new(1, 3, Prosereflect::Transform::Slice.new(content2))
      expect(step1.can_prepend_content?(step2)).to be true
    end

    it "returns false when other.slice is empty" do
      content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "y")])
      step1 = described_class.new(3, 3, Prosereflect::Transform::Slice.new(content))
      step2 = described_class.new(1, 3, Prosereflect::Transform::Slice.empty)
      expect(step1.can_prepend_content?(step2)).to be false
    end

    it "returns false when other ends at different position" do
      content = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "y")])
      step1 = described_class.new(3, 3, Prosereflect::Transform::Slice.new(content))
      content2 = Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")])
      step2 = described_class.new(1, 2, Prosereflect::Transform::Slice.new(content2))
      expect(step1.can_prepend_content?(step2)).to be false
    end
  end
end
