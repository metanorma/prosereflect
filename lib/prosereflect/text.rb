# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class Text < Node
    attr_reader :text
    attr_accessor :marks

    def initialize(data = {})
      super
      @text = data['text'] || ''
    end

    def text_content
      @text || ''
    end

    # Create a new text node
    def self.create(text, marks = nil)
      node = new({ 'type' => 'text', 'text' => text })
      node.instance_variable_set(:@marks, marks) if marks
      node
    end

    # Convert to hash representation
    def to_h
      result = super
      result['text'] = @text if @text
      result
    end
  end
end
