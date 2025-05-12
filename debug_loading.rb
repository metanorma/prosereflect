#!/usr/bin/env ruby
# frozen_string_literal: true

puts 'Debug script to check class loading'

begin
  puts '1. Adding lib to path'
  $LOAD_PATH.unshift File.expand_path('lib', __dir__)
  puts "Load path: #{$LOAD_PATH.inspect}"

  puts "\n2. Requiring prosereflect"
  require 'prosereflect'
  puts 'Successfully required prosereflect'

  puts "\n3. Checking Prosereflect module"
  puts "Prosereflect defined? #{!defined?(Prosereflect).nil?}"
  puts "Prosereflect is a #{Prosereflect.class}"

  puts "\n4. Checking individual classes"
  classes = %w[Node Document Paragraph Text HardBreak Table TableRow TableCell Parser]
  classes.each do |klass|
    full_class = "Prosereflect::#{klass}"
    is_defined = begin
      !defined?(Object.const_get(full_class)).nil?
    rescue StandardError
      false
    end
    puts "#{full_class} defined? #{is_defined}"
    puts "  #{full_class} is a #{Object.const_get(full_class).class}" if is_defined
  end
rescue StandardError => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts e.backtrace
end
