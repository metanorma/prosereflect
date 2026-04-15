# frozen_string_literal: true

require "spec_helper"
require_relative "../../fixtures/test_builder/helpers"

RSpec.describe TestBuilder do # rubocop:disable RSpec/SpecFilePathFormat
  describe ".extract_markers" do
    it "extracts an anchor marker and its position" do
      _content, positions = described_class.extract_markers('doc(p("hello<|a> world"))')
      expect(positions).to include("a")
      expect(positions["a"]).to eq(12)
    end

    it "extracts a cursor position marker" do
      _content, positions = described_class.extract_markers('doc(p("hello<|> world"))')
      expect(positions).to include(:cursor)
      expect(positions[:cursor]).to eq(12)
    end

    it "extracts a numbered position marker" do
      _content, positions = described_class.extract_markers('doc(p("hello<1> world"))')
      expect(positions).to include(1)
      expect(positions[1]).to eq(12)
    end

    it "extracts multiple markers from a single string" do
      _content, positions = described_class.extract_markers('doc(p("hello<|a> world<|b>"))')
      expect(positions).to include("a", "b")
      expect(positions["a"]).to be < positions["b"]
    end

    it "returns an empty positions hash when no markers are present" do
      _content, positions = described_class.extract_markers('doc(p("hello world"))')
      expect(positions).to be_empty
    end

    it "returns the content string with all markers removed" do
      content, _positions = described_class.extract_markers('doc(p("hello<|a> world<1>"))')
      expect(content).to eq('doc(p("hello world"))')
    end

    it "removes a cursor marker from the content string" do
      content, _positions = described_class.extract_markers('doc(p("hello<|> world"))')
      expect(content).to eq('doc(p("hello world"))')
    end

    it "returns a two-element array of [cleaned_string, positions_hash]" do
      result = described_class.extract_markers('doc(p("hello<|> world"))')
      expect(result).to be_a(Array)
      expect(result.size).to eq(2)
      expect(result[0]).to be_a(String)
      expect(result[1]).to be_a(Hash)
    end
  end

  describe ".parse" do
    it "delegates to Builder#parse" do
      builder = described_class.for_schema(nil)
      expect(builder).to be_a(TestBuilder::Builder)
    end

    it "returns nil when extract_content returns nil" do
      # For strings where extract_content cannot find matching outer parens,
      # parse returns nil.
      doc = described_class.parse("hello")
      expect(doc).to be_nil
    end
  end

  describe ".for_schema" do
    it "returns a Builder instance" do
      builder = described_class.for_schema(nil)
      expect(builder).to be_a(TestBuilder::Builder)
    end

    it "assigns the schema to the builder" do
      schema = Prosereflect::Schema.new(
        nodes_spec: {
          "doc" => { content: "block+" },
          "paragraph" => { content: "inline*", group: "block" },
          "text" => { group: "inline" },
        },
        marks_spec: {
          "em" => { group: "mark" },
          "strong" => { group: "mark" },
        },
      )
      builder = described_class.for_schema(schema)
      expect(builder.schema).to eq(schema)
    end

    it "creates a builder with nil schema by default" do
      builder = described_class.for_schema(nil)
      expect(builder.schema).to be_nil
    end
  end

  describe TestBuilder::Builder do
    describe "#parse_content" do
      it "parses a bare string literal into a string" do
        builder = described_class.new
        result = builder.parse_content('"hello"')
        expect(result).to eq("hello")
      end
    end

    describe "#schema" do
      it "is nil by default" do
        builder = described_class.new
        expect(builder.schema).to be_nil
      end

      it "stores the provided schema" do
        schema = Prosereflect::Schema.new(
          nodes_spec: {
            "doc" => { content: "block+" },
            "paragraph" => { content: "inline*", group: "block" },
            "text" => { group: "inline" },
          },
          marks_spec: {},
        )
        builder = described_class.new(schema: schema)
        expect(builder.schema).to eq(schema)
      end
    end
  end
end
