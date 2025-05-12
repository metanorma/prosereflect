#!/usr/bin/env ruby
# frozen_string_literal: true

# This script extracts ProseMirror content from the ITU Operational Bulletin
# "Old Issues" dataset located at:
# https://github.com/ituob/itu-ob-data/
#
# It processes the `amendments.yaml` file and generates YAML and JSON files for
# spec testing usage.
#
# The `amendments.yaml` files are located at
# itu-ob-data:/issues/{issue-number}/amendments.yaml.

require 'yaml'
require 'json'

# Check for correct arguments
if ARGV.length < 2
  puts 'Usage: ruby extract-amendments-ituob.rb <amendments_file> <issue_number>'
  puts 'Example: ruby extract-amendments-ituob.rb amendments.yaml 1000'
  exit 1
end

# Get command line arguments
amendments_file = ARGV[0]
issue_number = ARGV[1]

# Load the amendments YAML file
begin
  # Use safe_load with allowed classes to handle Time objects
  amendments = YAML.safe_load(File.read(amendments_file), permitted_classes: [Time, Date, Symbol])
rescue StandardError => e
  puts "Error loading YAML file: #{e.message}"
  exit 1
end

# Process each message
amendments['messages'].each do |message|
  next unless message['type'] == 'amendment' && message['target'] && message['target']['publication'] && message['contents'] && message['contents']['en']

  # Extract target publication
  publication = message['target']['publication']

  # Extract content
  content = message['contents']['en']

  # Create output filenames
  yaml_filename = "ituob-#{issue_number}-#{publication}.yaml"
  json_filename = "ituob-#{issue_number}-#{publication}.json"

  # Write content to YAML file
  File.open(yaml_filename, 'w') do |file|
    file.write(content.to_yaml)
  end

  # Write content to JSON file
  File.open(json_filename, 'w') do |file|
    file.write(JSON.pretty_generate(content))
  end

  puts "Created #{yaml_filename} and #{json_filename}"
end

files_count = amendments['messages'].count do |msg|
  msg['type'] == 'amendment' && msg['target'] && msg['target']['publication']
end
puts "Extraction complete. Created #{files_count} YAML files and #{files_count} JSON files with issue number #{issue_number}."
