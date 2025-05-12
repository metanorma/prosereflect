# frozen_string_literal: true

require 'yaml'
require 'json'

# Custom RSpec matcher for comparing JSON structures
RSpec::Matchers.define :be_equivalent_json do |expected|
  match do |actual|
    # Parse strings if needed
    expected_hash = expected.is_a?(String) ? JSON.parse(expected) : expected
    actual_hash = actual.is_a?(String) ? JSON.parse(actual) : actual

    # Compare the parsed structures
    expected_hash == actual_hash
  end

  failure_message do |actual|
    expected_hash = expected.is_a?(String) ? JSON.parse(expected) : expected
    actual_hash = actual.is_a?(String) ? JSON.parse(actual) : actual

    "Expected JSON to be equivalent to #{expected_hash.inspect}, but got #{actual_hash.inspect}"
  end
end

# Custom RSpec matcher for comparing YAML structures
RSpec::Matchers.define :be_equivalent_yaml do |expected|
  match do |actual|
    # Parse strings if needed
    expected_hash = expected.is_a?(String) ? YAML.safe_load(expected) : expected
    actual_hash = actual.is_a?(String) ? YAML.safe_load(actual) : actual

    # Compare the parsed structures
    expected_hash == actual_hash
  end

  failure_message do |actual|
    expected_hash = expected.is_a?(String) ? YAML.safe_load(expected) : expected
    actual_hash = actual.is_a?(String) ? YAML.safe_load(actual) : actual

    "Expected YAML to be equivalent to #{expected_hash.inspect}, but got #{actual_hash.inspect}"
  end
end

# Helper method to recursively compare hashes and arrays
def deep_compare(expected, actual)
  return expected == actual unless expected.is_a?(Hash) || expected.is_a?(Array)

  if expected.is_a?(Hash) && actual.is_a?(Hash)
    return false unless expected.keys.sort == actual.keys.sort

    expected.all? { |key, value| deep_compare(value, actual[key]) }
  elsif expected.is_a?(Array) && actual.is_a?(Array)
    return false unless expected.length == actual.length

    expected.zip(actual).all? { |e, a| deep_compare(e, a) }
  else
    false
  end
end

# More flexible matcher that handles structural equivalence
RSpec::Matchers.define :have_equivalent_structure do |expected|
  match do |actual|
    # Parse strings if needed
    expected_data = case expected
                    when String
                      if expected.strip.start_with?('{', '[')
                        begin
                          JSON.parse(expected)
                        rescue StandardError
                          YAML.safe_load(expected)
                        end
                      else
                        YAML.safe_load(expected)
                      end
                    else
                      expected
                    end

    actual_data = case actual
                  when String
                    if actual.strip.start_with?('{', '[')
                      begin
                        JSON.parse(actual)
                      rescue StandardError
                        YAML.safe_load(actual)
                      end
                    else
                      YAML.safe_load(actual)
                    end
                  else
                    actual
                  end

    deep_compare(expected_data, actual_data)
  end

  failure_message do |actual|
    expected_data = case expected
                    when String
                      if expected.strip.start_with?('{', '[')
                        begin
                          JSON.parse(expected)
                        rescue StandardError
                          YAML.safe_load(expected)
                        end
                      else
                        YAML.safe_load(expected)
                      end
                    else
                      expected
                    end

    actual_data = case actual
                  when String
                    if actual.strip.start_with?('{', '[')
                      begin
                        JSON.parse(actual)
                      rescue StandardError
                        YAML.safe_load(actual)
                      end
                    else
                      YAML.safe_load(actual)
                    end
                  else
                    actual
                  end

    "Expected structures to be equivalent:\nExpected: #{expected_data.inspect}\nActual: #{actual_data.inspect}"
  end
end
