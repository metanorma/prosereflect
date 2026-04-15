# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect::Transform::Transform do
  let(:doc) { Prosereflect::Document.new }

  describe "creation" do
    it "creates transform with document" do
      transform = described_class.new(doc)
      expect(transform.doc).to eq(doc)
    end

    it "starts with empty steps" do
      transform = described_class.new(doc)
      expect(transform.size).to eq(0)
    end
  end

  describe "add_mark" do
    it "adds mark step to transform" do
      transform = described_class.new(doc)
      mark = Prosereflect::Mark::Bold.new
      transform.add_mark(0, 10, mark)
      expect(transform.size).to eq(1)
    end
  end

  describe "remove_mark" do
    it "adds remove mark step to transform" do
      transform = described_class.new(doc)
      mark = Prosereflect::Mark::Bold.new
      transform.remove_mark(0, 10, mark)
      expect(transform.size).to eq(1)
    end
  end

  describe "insert" do
    it "adds insert step to transform" do
      transform = described_class.new(doc)
      text = Prosereflect::Text.new(text: "hello")
      transform.insert(0, text)
      expect(transform.size).to eq(1)
    end
  end

  describe "delete" do
    it "adds delete step to transform" do
      transform = described_class.new(doc)
      transform.delete(0, 5)
      expect(transform.size).to eq(1)
    end
  end

  describe "replace" do
    it "adds replace step to transform" do
      transform = described_class.new(doc)
      slice = Prosereflect::Transform::Slice.empty
      transform.replace(0, 5, slice)
      expect(transform.size).to eq(1)
    end

    it "defaults to empty slice" do
      transform = described_class.new(doc)
      transform.replace(0, 5)
      expect(transform.size).to eq(1)
    end
  end

  describe "replace_with" do
    it "adds replace step with nodes" do
      transform = described_class.new(doc)
      text = Prosereflect::Text.new(text: "x")
      transform.replace_with(0, 5, text)
      expect(transform.size).to eq(1)
    end

    it "accepts multiple nodes" do
      transform = described_class.new(doc)
      t1 = Prosereflect::Text.new(text: "a")
      t2 = Prosereflect::Text.new(text: "b")
      transform.replace_with(0, 5, t1, t2)
      expect(transform.size).to eq(1)
    end
  end

  describe "set_node_attribute" do
    it "adds attr step to transform" do
      transform = described_class.new(doc)
      transform.set_node_attribute(0, { "level" => 2 })
      expect(transform.size).to eq(1)
    end
  end

  describe "set_doc_attribute" do
    it "adds doc attr step to transform" do
      transform = described_class.new(doc)
      transform.set_doc_attribute({ "meta" => 1 })
      expect(transform.size).to eq(1)
    end
  end

  describe "empty?" do
    it "returns true for new transform" do
      transform = described_class.new(doc)
      expect(transform.empty?).to be true
    end

    it "returns false after adding step" do
      transform = described_class.new(doc)
      transform.delete(0, 5)
      expect(transform.empty?).to be false
    end
  end

  describe "clone" do
    it "creates new transform with same document" do
      transform = described_class.new(doc)
      cloned = transform.clone
      expect(cloned.doc).to eq(doc)
    end

    it "clone does not share steps" do
      transform = described_class.new(doc)
      transform.delete(0, 5)
      cloned = transform.clone
      expect(cloned.size).to eq(0)
    end
  end

  describe "rollback" do
    it "returns self for chaining on empty transform" do
      transform = described_class.new(doc)
      result = transform.rollback
      expect(result).to eq(transform)
    end
  end

  describe "maps" do
    it "returns empty mapping array for new transform" do
      transform = described_class.new(doc)
      expect(transform.maps).to eq([])
    end

    it "returns mapping after adding steps" do
      transform = described_class.new(doc)
      transform.delete(0, 5)
      expect(transform.maps.length).to eq(1)
    end
  end

  describe "size" do
    it "returns number of steps" do
      transform = described_class.new(doc)
      expect(transform.size).to eq(0)

      transform.delete(0, 5)
      expect(transform.size).to eq(1)

      transform.delete(0, 5)
      expect(transform.size).to eq(2)
    end
  end

  describe "add_step" do
    it "returns self for chaining" do
      transform = described_class.new(doc)
      step = Prosereflect::Transform::ReplaceStep.new(0, 5)
      result = transform.add_step(step)
      expect(result).to eq(transform)
    end

    it "tracks mapping" do
      transform = described_class.new(doc)
      step = Prosereflect::Transform::ReplaceStep.new(0, 5)
      transform.add_step(step)
      expect(transform.maps.length).to eq(1)
    end
  end

  describe "split" do
    it "adds split step to transform" do
      doc_with_content = Prosereflect::Parser.parse_document({
                                                               "type" => "doc",
                                                               "content" => [
                                                                 {
                                                                   "type" => "paragraph",
                                                                   "content" => [
                                                                     { "type" => "text", "text" => "Hello World" },
                                                                   ],
                                                                 },
                                                               ],
                                                             })
      transform = described_class.new(doc_with_content)
      transform.split(5)
      expect(transform.size).to eq(1)
    end
  end

  describe "join" do
    it "adds join step to transform" do
      doc_with_two_paras = Prosereflect::Parser.parse_document({
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
      transform = described_class.new(doc_with_two_paras)
      transform.join(8)
      expect(transform.size).to eq(1)
    end
  end

  describe "to_s" do
    it "returns string representation" do
      transform = described_class.new(doc)
      expect(transform.to_s).to include("Transform")
    end
  end

  describe "inspect" do
    it "returns same as to_s" do
      transform = described_class.new(doc)
      expect(transform.inspect).to eq(transform.to_s)
    end
  end
end
