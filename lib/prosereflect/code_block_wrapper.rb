# frozen_string_literal: true

require_relative 'node'
require_relative 'code_block'

module Prosereflect
  # CodeBlockWrapper class represents a pre tag that wraps code blocks in ProseMirror.
  class CodeBlockWrapper < Node
    PM_TYPE = 'code_block_wrapper'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :line_numbers, :boolean
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      attributes[:attrs] = {
        'line_numbers' => false
      }
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def line_numbers=(value)
      @line_numbers = value
      self.attrs ||= {}
      attrs['line_numbers'] = value
    end

    def line_numbers
      @line_numbers || attrs&.[]('line_numbers') || false
    end

    def add_code_block(code = nil)
      block = CodeBlock.new
      block.content = code if code
      add_child(block)
      block
    end

    def code_blocks
      content
    end

    def text_content
      code_blocks.map(&:text_content).join("\n")
    end

    def to_h
      hash = super
      hash['attrs'] = {
        'line_numbers' => line_numbers
      }
      hash
    end
  end
end
