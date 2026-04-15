# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Fragment do
  describe "creation" do
    it "creates empty fragment" do
      frag = described_class.new
      expect(frag.empty?).to be true
    end

    it "creates fragment with content" do
      node = Prosereflect::Paragraph.new
      frag = described_class.new([node])
      expect(frag.empty?).to be false
      expect(frag.length).to eq(1)
    end

    it "creates fragment from single node" do
      node = Prosereflect::Text.new(text: "hello")
      frag = described_class.new(node)
      expect(frag.length).to eq(1)
    end
  end

  describe ".empty" do
    it "returns a shared empty fragment" do
      frag1 = described_class.empty
      frag2 = described_class.empty
      expect(frag1).to equal(frag2)
      expect(frag1.empty?).to be true
    end
  end

  describe ".from" do
    it "returns same fragment when given a fragment" do
      frag = described_class.new
      expect(described_class.from(frag)).to equal(frag)
    end

    it "wraps array in fragment" do
      node = Prosereflect::Text.new(text: "x")
      frag = described_class.from([node])
      expect(frag).to be_a(described_class)
      expect(frag.length).to eq(1)
    end

    it "wraps single node in fragment" do
      node = Prosereflect::Text.new(text: "x")
      frag = described_class.from(node)
      expect(frag.length).to eq(1)
    end
  end

  describe "size" do
    it "returns 0 for empty fragment" do
      expect(described_class.new.size).to eq(0)
    end

    it "returns total node sizes" do
      text = Prosereflect::Text.new(text: "hello")
      frag = described_class.new([text])
      # text "hello" has node_size = 5 + 1 = 6
      expect(frag.size).to eq(6)
    end

    it "sums multiple nodes" do
      t1 = Prosereflect::Text.new(text: "ab")
      t2 = Prosereflect::Text.new(text: "cd")
      frag = described_class.new([t1, t2])
      # 3 + 3 = 6
      expect(frag.size).to eq(6)
    end
  end

  describe "append" do
    it "appends another fragment" do
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2])
      result = frag1.append(frag2)
      expect(result.length).to eq(2)
    end

    it "appends a single node" do
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      frag = described_class.new([t1])
      result = frag.append(t2)
      expect(result.length).to eq(2)
    end

    it "does not mutate original" do
      t1 = Prosereflect::Text.new(text: "a")
      frag = described_class.new([t1])
      frag.append(described_class.new)
      expect(frag.length).to eq(1)
    end
  end

  describe "cut" do
    it "returns empty fragment for empty cut" do
      frag = described_class.new
      result = frag.cut(0, 0)
      expect(result).to be_a(described_class)
      expect(result.empty?).to be true
    end

    it "returns empty when from >= to" do
      text = Prosereflect::Text.new(text: "hello")
      frag = described_class.new([text])
      result = frag.cut(3, 3)
      expect(result.empty?).to be true
    end
  end

  describe "replace_child" do
    it "replaces child at index" do
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      replacement = Prosereflect::Text.new(text: "c")
      frag = described_class.new([t1, t2])
      result = frag.replace_child(0, replacement)
      expect(result[0]).to eq(replacement)
      expect(result[1]).to eq(t2)
    end

    it "does not mutate original" do
      t1 = Prosereflect::Text.new(text: "a")
      replacement = Prosereflect::Text.new(text: "c")
      frag = described_class.new([t1])
      frag.replace_child(0, replacement)
      expect(frag[0]).to eq(t1)
    end
  end

  describe "index access" do
    it "returns nil for out of bounds" do
      frag = described_class.new
      expect(frag[0]).to be_nil
    end

    it "returns node at index" do
      node = Prosereflect::Text.new(text: "x")
      frag = described_class.new([node])
      expect(frag[0]).to eq(node)
    end
  end

  describe "iteration" do
    it "iterates over content" do
      node = Prosereflect::Paragraph.new
      frag = described_class.new([node])
      count = 0
      frag.each { count += 1 }
      expect(count).to eq(1)
    end

    it "returns count" do
      frag = described_class.new([Prosereflect::Text.new(text: "a"),
                                  Prosereflect::Text.new(text: "b")])
      expect(frag.count).to eq(2)
      expect(frag.length).to eq(2)
    end
  end

  describe "equality" do
    it "compares equal fragments" do
      frag1 = described_class.new
      frag2 = described_class.new
      expect(frag1).to eq(frag2)
    end

    it "compares unequal fragments" do
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2])
      expect(frag1).not_to eq(frag2)
    end
  end

  describe "text_between" do
    it "extracts text from nodes in range" do
      text = Prosereflect::Text.new(text: "hello")
      frag = described_class.new([text])
      expect(frag.text_between(0, 5)).to eq("hello")
    end

    it "joins multiple nodes" do
      t1 = Prosereflect::Text.new(text: "hello")
      t2 = Prosereflect::Text.new(text: "world")
      frag = described_class.new([t1, t2])
      expect(frag.text_between(0, 10)).to eq("helloworld")
    end

    it "joins with separator" do
      t1 = Prosereflect::Text.new(text: "hello")
      t2 = Prosereflect::Text.new(text: "world")
      frag = described_class.new([t1, t2])
      expect(frag.text_between(0, 10, " ")).to eq("hello world")
    end
  end

  describe "find_diff_start" do
    it "returns nil for identical fragments" do
      t1 = Prosereflect::Text.new(text: "hello")
      t2 = Prosereflect::Text.new(text: "hello")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2])
      expect(frag1.find_diff_start(frag2)).to be_nil
    end

    it "returns 0 for completely different first nodes" do
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2])
      expect(frag1.find_diff_start(frag2)).to eq(0)
    end

    it "returns position where fragments differ" do
      t1 = Prosereflect::Text.new(text: "hello")
      t2 = Prosereflect::Text.new(text: "hello")
      t3 = Prosereflect::Text.new(text: "world")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2, t3])
      # Same first node, but different lengths
      expect(frag1.find_diff_start(frag2)).to eq(6) # node_size of "hello"
    end
  end

  describe "find_diff_end" do
    it "returns nil for identical fragments" do
      t1 = Prosereflect::Text.new(text: "hello")
      t2 = Prosereflect::Text.new(text: "hello")
      frag1 = described_class.new([t1])
      frag2 = described_class.new([t2])
      expect(frag1.find_diff_end(frag2)).to be_nil
    end

    it "returns position where trailing content differs" do
      t1 = Prosereflect::Text.new(text: "ab")
      t2 = Prosereflect::Text.new(text: "cd")
      t3 = Prosereflect::Text.new(text: "ef")
      frag1 = described_class.new([t1, t2])
      frag2 = described_class.new([t3, t2])
      # The last nodes ("cd") are the same, first nodes differ
      # find_diff_end walks backward from the end and returns where they differ
      result = frag1.find_diff_end(frag2)
      expect(result).not_to be_nil
    end
  end

  describe "to_a" do
    it "returns a copy of the content array" do
      node = Prosereflect::Text.new(text: "x")
      frag = described_class.new([node])
      arr = frag.to_a
      expect(arr).to eq([node])
      expect(arr).not_to equal(frag.content)
    end
  end

  describe "to_s / inspect" do
    it "returns string representation" do
      frag = described_class.new([Prosereflect::Text.new(text: "x")])
      expect(frag.to_s).to include("Fragment")
      expect(frag.inspect).to eq(frag.to_s)
    end
  end
end
