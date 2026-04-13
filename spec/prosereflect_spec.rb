# frozen_string_literal: true

require "spec_helper"

RSpec.describe Prosereflect do
  let(:fixtures_path) { File.join(__dir__, "fixtures") }

  it "has a version number" do
    expect(Prosereflect::VERSION).not_to be_nil
    expect(Prosereflect::VERSION).to be_a(String)
    expect(Prosereflect::VERSION).to match(/\d+\.\d+\.\d+/)
  end

  # Test YAML parsing for different fixtures
  Dir.glob(File.join(__dir__, "fixtures", "*/*.yaml")).each do |yaml_file|
    context "with YAML fixture #{File.basename(yaml_file)}" do
      let(:file_content) { File.read(yaml_file) }

      it_behaves_like "a parsable format", :yaml

      # Test table functionality for DP fixtures
      if yaml_file.include?("DP")
        it_behaves_like "a document with tables"
        it_behaves_like "document traversal"
        it_behaves_like "text content extraction"
      end
    end
  end

  # Test JSON parsing for different fixtures
  Dir.glob(File.join(__dir__, "fixtures", "*/*.json")).each do |json_file|
    context "with JSON fixture #{File.basename(json_file)}" do
      let(:file_content) { File.read(json_file) }

      it_behaves_like "a parsable format", :json

      # Test table functionality for DP fixtures
      if json_file.include?("DP")
        it_behaves_like "a document with tables"
        it_behaves_like "document traversal"
        it_behaves_like "text content extraction"
      end
    end
  end

  describe "Document creation" do
    it_behaves_like "document creation"
  end

  describe "Round-trip format conversion" do
    context "with YAML format" do
      it_behaves_like "format round-trip", :yaml
    end

    context "with JSON format" do
      it_behaves_like "format round-trip", :json
    end

    context "with HTML format" do
      it_behaves_like "format round-trip", :html
      it_behaves_like "html conversion"
    end
  end
end
