# frozen_string_literal: true

require "spec_helper"
require "prosereflect/output/html"

RSpec.describe Prosereflect::Output::DOMSerializer do # rubocop:disable RSpec/SpecFilePathFormat
  let(:serializer) { described_class.new(nil) }

  describe "#preserve_whitespace?" do
    it "returns true for code_block nodes" do
      code_block = Prosereflect::CodeBlock.new
      expect(serializer.send(:preserve_whitespace?, code_block)).to be true
    end

    it "returns true for code_block_wrapper nodes" do
      wrapper = Prosereflect::CodeBlockWrapper.new
      expect(serializer.send(:preserve_whitespace?, wrapper)).to be true
    end

    it "returns true for pre type nodes" do
      node = Prosereflect::Node.new("pre")
      expect(serializer.send(:preserve_whitespace?, node)).to be true
    end

    it "returns true for nodes with white-space: pre in style attrs" do
      node = Prosereflect::Node.new("paragraph")
      node.attrs = { "style" => "white-space: pre; color: red" }
      expect(serializer.send(:preserve_whitespace?, node)).to be true
    end

    it "returns false for paragraph nodes" do
      paragraph = Prosereflect::Paragraph.new
      expect(serializer.send(:preserve_whitespace?, paragraph)).to be false
    end

    it "returns false for heading nodes" do
      heading = Prosereflect::Heading.new
      heading.level = 1
      expect(serializer.send(:preserve_whitespace?, heading)).to be false
    end

    it "returns false for nodes without white-space: pre style" do
      node = Prosereflect::Node.new("paragraph")
      node.attrs = { "style" => "color: red" }
      expect(serializer.send(:preserve_whitespace?, node)).to be false
    end

    it "returns false for nodes with non-string style attrs" do
      node = Prosereflect::Node.new("paragraph")
      node.attrs = { "style" => 123 }
      expect(serializer.send(:preserve_whitespace?, node)).to be false
    end

    it "returns false when node does not respond to type" do
      expect(serializer.send(:preserve_whitespace?, "not a node")).to be false
    end

    it "returns false when node does not respond to attrs" do
      node = Prosereflect::Node.new("text")
      allow(node).to receive(:respond_to?).and_call_original
      expect(serializer.send(:preserve_whitespace?, node)).to be false
    end
  end

  describe "#whitespace_mode" do
    it "returns :preserve for code_block nodes" do
      code_block = Prosereflect::CodeBlock.new
      expect(serializer.send(:whitespace_mode, code_block)).to eq(:preserve)
    end

    it "returns :preserve for code_block_wrapper nodes" do
      wrapper = Prosereflect::CodeBlockWrapper.new
      expect(serializer.send(:whitespace_mode, wrapper)).to eq(:preserve)
    end

    it "returns :collapse for paragraph nodes" do
      paragraph = Prosereflect::Paragraph.new
      expect(serializer.send(:whitespace_mode, paragraph)).to eq(:collapse)
    end

    it "returns :collapse for heading nodes" do
      heading = Prosereflect::Heading.new
      heading.level = 2
      expect(serializer.send(:whitespace_mode, heading)).to eq(:collapse)
    end

    it "returns :preserve for nodes with white-space: pre style" do
      node = Prosereflect::Node.new("paragraph")
      node.attrs = { "style" => "white-space: pre" }
      expect(serializer.send(:whitespace_mode, node)).to eq(:preserve)
    end
  end

  describe "#collapse_whitespace" do
    it "collapses multiple spaces into one" do
      expect(serializer.send(:collapse_whitespace, "hello   world")).to eq("hello world")
    end

    it "collapses tabs into a single space" do
      expect(serializer.send(:collapse_whitespace, "hello\tworld")).to eq("hello world")
    end

    it "collapses mixed tabs and spaces into a single space" do
      expect(serializer.send(:collapse_whitespace, "hello \t  world")).to eq("hello world")
    end

    it "collapses leading spaces" do
      expect(serializer.send(:collapse_whitespace, "  hello")).to eq(" hello")
    end

    it "collapses trailing spaces" do
      expect(serializer.send(:collapse_whitespace, "hello  ")).to eq("hello ")
    end

    it "collapses both leading and trailing spaces" do
      expect(serializer.send(:collapse_whitespace, "  hello   world  ")).to eq(" hello world ")
    end

    it "handles a single space string" do
      expect(serializer.send(:collapse_whitespace, " ")).to eq(" ")
    end

    it "handles an empty string" do
      expect(serializer.send(:collapse_whitespace, "")).to eq("")
    end

    it "does not modify a string with no extra whitespace" do
      expect(serializer.send(:collapse_whitespace, "hello world")).to eq("hello world")
    end
  end

  describe "#normalize_whitespace" do
    it "replaces tabs with spaces" do
      expect(serializer.send(:normalize_whitespace, "hello\tworld")).to eq("hello world")
    end

    it "replaces newlines with spaces" do
      expect(serializer.send(:normalize_whitespace, "hello\nworld")).to eq("hello world")
    end

    it "replaces carriage returns with spaces" do
      expect(serializer.send(:normalize_whitespace, "hello\rworld")).to eq("hello world")
    end

    it "replaces mixed whitespace with a single space" do
      expect(serializer.send(:normalize_whitespace, "hello \t\n\r world")).to eq("hello world")
    end

    it "collapses multiple spaces into one" do
      expect(serializer.send(:normalize_whitespace, "hello    world")).to eq("hello world")
    end

    it "handles a string with only whitespace" do
      expect(serializer.send(:normalize_whitespace, "\t\n\r")).to eq(" ")
    end

    it "handles an empty string" do
      expect(serializer.send(:normalize_whitespace, "")).to eq("")
    end

    it "does not modify a string with no extra whitespace" do
      expect(serializer.send(:normalize_whitespace, "hello world")).to eq("hello world")
    end
  end

  describe "#process_text_whitespace" do
    context "when node preserves whitespace" do
      it "returns text unchanged for code_block nodes" do
        code_block = Prosereflect::CodeBlock.new
        text = "  hello\n  world  "
        expect(serializer.send(:process_text_whitespace, text, code_block)).to eq("  hello\n  world  ")
      end

      it "returns text unchanged for code_block_wrapper nodes" do
        wrapper = Prosereflect::CodeBlockWrapper.new
        text = "  hello\n  world  "
        expect(serializer.send(:process_text_whitespace, text, wrapper)).to eq("  hello\n  world  ")
      end

      it "returns text unchanged for nodes with white-space: pre style" do
        node = Prosereflect::Node.new("paragraph")
        node.attrs = { "style" => "white-space: pre" }
        text = "  hello\n  world  "
        expect(serializer.send(:process_text_whitespace, text, node)).to eq("  hello\n  world  ")
      end
    end

    context "when node collapses whitespace" do
      it "collapses whitespace for paragraph nodes" do
        paragraph = Prosereflect::Paragraph.new
        text = "hello   world"
        expect(serializer.send(:process_text_whitespace, text, paragraph)).to eq("hello world")
      end

      it "collapses whitespace for heading nodes" do
        heading = Prosereflect::Heading.new
        heading.level = 1
        text = "hello   world"
        expect(serializer.send(:process_text_whitespace, text, heading)).to eq("hello world")
      end

      it "collapses tabs and spaces for regular nodes" do
        paragraph = Prosereflect::Paragraph.new
        text = "  hello \t world  "
        expect(serializer.send(:process_text_whitespace, text, paragraph)).to eq(" hello world ")
      end
    end
  end

  describe "DOMSerializer serialization" do
    it "serializes a single node via #serialize_node" do
      paragraph = Prosereflect::Paragraph.new
      paragraph.add_text("Hello")

      result = serializer.serialize_node(paragraph)
      expect(result).to include("Hello")
    end

    it "returns text unchanged via #render_text when no schema is set" do
      text = "bold text"
      bold_mark = Prosereflect::Mark::Bold.new

      result = serializer.render_text(text, [bold_mark])
      # Without a schema, build_mark_serializers returns {},
      # so apply_mark returns content unmodified
      expect(result).to eq("bold text")
    end

    it "returns text unchanged via #render_text with multiple marks and no schema" do
      text = "bold italic"
      bold_mark = Prosereflect::Mark::Bold.new
      italic_mark = Prosereflect::Mark::Italic.new

      result = serializer.render_text(text, [bold_mark, italic_mark])
      expect(result).to eq("bold italic")
    end

    it "renders text without marks via #render_text" do
      result = serializer.render_text("plain text", [])
      expect(result).to eq("plain text")
    end

    it "renders text with nil marks via #render_text" do
      result = serializer.render_text("plain text", nil)
      expect(result).to eq("plain text")
    end
  end
end
