# frozen_string_literal: true

require_relative 'prosereflect/version'
require_relative 'prosereflect/node'
require_relative 'prosereflect/mark'
require_relative 'prosereflect/attribute'
require_relative 'prosereflect/text'
require_relative 'prosereflect/paragraph'
require_relative 'prosereflect/hard_break'
require_relative 'prosereflect/table'
require_relative 'prosereflect/table_row'
require_relative 'prosereflect/table_cell'
require_relative 'prosereflect/heading'
require_relative 'prosereflect/document'
require_relative 'prosereflect/parser'
require_relative 'prosereflect/input/html'
require_relative 'prosereflect/output/html'

module Prosereflect
  class Error < StandardError; end
  # Your code goes here...
end
