# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Prosereflect do
  let(:fixtures_path) { File.join(__dir__, 'fixtures') }

  it 'has a version number' do
    expect(Prosereflect::VERSION).not_to be nil
  end

  # Test YAML parsing for different fixtures
  Dir.glob(File.join(__dir__, 'fixtures', '*/*.yaml')).each do |yaml_file|
    context "with YAML fixture #{File.basename(yaml_file)}" do
      let(:file_content) { File.read(yaml_file) }

      include_examples 'a parsable format', :yaml

      # Test table functionality for DP fixtures
      if yaml_file.include?('DP')
        include_examples 'a document with tables'
        include_examples 'document traversal'
        include_examples 'text content extraction'
      end
    end
  end

  # Test JSON parsing for different fixtures
  Dir.glob(File.join(__dir__, 'fixtures', '*/*.json')).each do |json_file|
    context "with JSON fixture #{File.basename(json_file)}" do
      let(:file_content) { File.read(json_file) }

      include_examples 'a parsable format', :json

      # Test table functionality for DP fixtures
      if json_file.include?('DP')
        include_examples 'a document with tables'
        include_examples 'document traversal'
        include_examples 'text content extraction'
      end
    end
  end

  describe 'Document creation' do
    include_examples 'document creation'
  end

  describe 'Round-trip format conversion' do
    context 'with YAML format' do
      include_examples 'format round-trip', :yaml
    end

    context 'with JSON format' do
      include_examples 'format round-trip', :json
    end

    context 'with HTML format' do
      include_examples 'format round-trip', :html
      include_examples 'html conversion'
    end
  end
end
