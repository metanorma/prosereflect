# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::Step do
  describe "creation" do
    it "can be instantiated" do
      step = described_class.new
      expect(step).to be_a(described_class)
    end
  end

  describe "merge" do
    it "merges adjacent empty deletions extending backward" do
      # step1: delete 3-4 (empty deletion at position 3)
      step1 = Prosereflect::Transform::ReplaceStep.new(
        3, 4,
        Prosereflect::Transform::Slice.empty
      )
      # step2: delete 2-3 (empty deletion at position 2)
      step2 = Prosereflect::Transform::ReplaceStep.new(
        2, 3,
        Prosereflect::Transform::Slice.empty
      )

      # step1's end (4) equals step2's start (2)? No, 4 != 2
      # step1's start (3) equals step2's end (3)? Yes!
      # can_prepend_deletion: other.to == @from && other.slice.empty?
      # 3 == 3 && true = true
      merged = step2.merge(step1)
      expect(merged).not_to be_nil
    end

    it "does not merge steps that are far apart" do
      step1 = Prosereflect::Transform::ReplaceStep.new(
        2, 2,
        Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "a")]),
        )
      )
      # step2 is at position 4, far from step1 at position 2
      step2 = Prosereflect::Transform::ReplaceStep.new(
        4, 4,
        Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "b")]),
        )
      )

      merged = step1.merge(step2)
      expect(merged).to be_nil
    end

    it "merges adjacent empty deletions" do
      # step1: delete 3-4
      step1 = Prosereflect::Transform::ReplaceStep.new(
        3, 4,
        Prosereflect::Transform::Slice.empty
      )
      # step2: delete 4-5 (adjacent - step1's end equals step2's start)
      step2 = Prosereflect::Transform::ReplaceStep.new(
        4, 5,
        Prosereflect::Transform::Slice.empty
      )

      # can_extend_deletion: @to == other.from && @slice.empty?
      # 4 == 4 && true = true
      merged = step1.merge(step2)
      expect(merged).not_to be_nil
    end

    it "does not merge overlapping deletions" do
      # step1: delete 1-3
      step1 = Prosereflect::Transform::ReplaceStep.new(
        1, 3,
        Prosereflect::Transform::Slice.empty
      )
      # step2: delete 2-4 (overlaps with step1)
      step2 = Prosereflect::Transform::ReplaceStep.new(
        2, 4,
        Prosereflect::Transform::Slice.empty
      )

      merged = step1.merge(step2)
      expect(merged).to be_nil
    end

    it "appends content when second step starts at first's end" do
      # step1: replace 2-3 with empty
      step1 = Prosereflect::Transform::ReplaceStep.new(
        2, 3,
        Prosereflect::Transform::Slice.empty
      )
      # step2: insert "x" at position 3 (step1's end)
      step2 = Prosereflect::Transform::ReplaceStep.new(
        3, 3,
        Prosereflect::Transform::Slice.new(
          Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")]),
        )
      )

      # can_append_content: @to == other.from && !other.slice.empty?
      merged = step1.merge(step2)
      expect(merged).not_to be_nil
    end
  end

  context "with ReplaceStep" do
    describe "creation" do
      it "creates replace step with from, to, and slice" do
        slice = Prosereflect::Transform::Slice.empty
        step = Prosereflect::Transform::ReplaceStep.new(0, 5, slice)
        expect(step.from).to eq(0)
        expect(step.to).to eq(5)
        expect(step.slice).to eq(slice)
      end

      it "creates replace step with default empty slice" do
        step = Prosereflect::Transform::ReplaceStep.new(0, 5)
        expect(step.slice).to eq(Prosereflect::Transform::Slice.empty)
      end
    end

    describe "get_map" do
      it "returns step map for the replacement" do
        step = Prosereflect::Transform::ReplaceStep.new(2, 5, Prosereflect::Transform::Slice.empty)
        step_map = step.get_map
        expect(step_map).to be_a(Prosereflect::Transform::StepMap)
      end
    end

    describe "step_type" do
      it "returns replace" do
        step = Prosereflect::Transform::ReplaceStep.new(0, 5)
        expect(step.step_type).to eq("replace")
      end
    end

    describe "can_extend_deletion?" do
      it "returns true when other starts at this end with empty slice" do
        step1 = Prosereflect::Transform::ReplaceStep.new(2, 4, Prosereflect::Transform::Slice.empty)
        step2 = Prosereflect::Transform::ReplaceStep.new(4, 6, Prosereflect::Transform::Slice.empty)
        expect(step1.can_extend_deletion?(step2)).to be true
      end

      it "returns false when other does not start at this end" do
        step1 = Prosereflect::Transform::ReplaceStep.new(2, 4, Prosereflect::Transform::Slice.empty)
        step2 = Prosereflect::Transform::ReplaceStep.new(5, 7, Prosereflect::Transform::Slice.empty)
        expect(step1.can_extend_deletion?(step2)).to be false
      end
    end

    describe "can_prepend_deletion?" do
      it "returns true when other ends at this start with empty slice" do
        step1 = Prosereflect::Transform::ReplaceStep.new(4, 6, Prosereflect::Transform::Slice.empty)
        step2 = Prosereflect::Transform::ReplaceStep.new(2, 4, Prosereflect::Transform::Slice.empty)
        expect(step1.can_prepend_deletion?(step2)).to be true
      end

      it "returns false when other does not end at this start" do
        step1 = Prosereflect::Transform::ReplaceStep.new(4, 6, Prosereflect::Transform::Slice.empty)
        step2 = Prosereflect::Transform::ReplaceStep.new(2, 3, Prosereflect::Transform::Slice.empty)
        expect(step1.can_prepend_deletion?(step2)).to be false
      end
    end

    describe "can_append_content?" do
      it "returns true when other starts at this end with content" do
        step1 = Prosereflect::Transform::ReplaceStep.new(2, 3, Prosereflect::Transform::Slice.empty)
        step2 = Prosereflect::Transform::ReplaceStep.new(
          3, 3,
          Prosereflect::Transform::Slice.new(
            Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")]),
          )
        )
        expect(step1.can_append_content?(step2)).to be true
      end
    end

    describe "can_prepend_content?" do
      it "returns true when other ends at this start with content" do
        # step1: insert "y" at position 3 (start=3, end=3)
        step1 = Prosereflect::Transform::ReplaceStep.new(
          3, 3,
          Prosereflect::Transform::Slice.new(
            Prosereflect::Fragment.new([Prosereflect::Text.new(text: "y")]),
          )
        )
        # step2: insert "x" at position 1-3 (ends at position 3 where step1 starts)
        step2 = Prosereflect::Transform::ReplaceStep.new(
          1, 3,
          Prosereflect::Transform::Slice.new(
            Prosereflect::Fragment.new([Prosereflect::Text.new(text: "x")]),
          )
        )
        expect(step1.can_prepend_content?(step2)).to be true
      end

      it "returns false when other.slice is empty" do
        step1 = Prosereflect::Transform::ReplaceStep.new(
          3, 3,
          Prosereflect::Transform::Slice.new(
            Prosereflect::Fragment.new([Prosereflect::Text.new(text: "y")]),
          )
        )
        # step2 has empty slice
        step2 = Prosereflect::Transform::ReplaceStep.new(1, 3, Prosereflect::Transform::Slice.empty)
        expect(step1.can_prepend_content?(step2)).to be false
      end
    end
  end
end
