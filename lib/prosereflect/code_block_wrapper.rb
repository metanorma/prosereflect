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

      # Extract attributes from the attrs hash if provided
      if attributes[:attrs]
        @line_numbers = attributes[:attrs]['line_numbers']
        @highlight_lines = parse_highlight_lines(attributes[:attrs]['highlight_lines'])
      end

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

    def highlight_lines=(lines)
      @highlight_lines = lines.is_a?(Array) ? lines : parse_highlight_lines(lines)
      self.attrs ||= {}
      attrs['highlight_lines'] = @highlight_lines.join(',')
    end

    def highlight_lines
      @highlight_lines || parse_highlight_lines(attrs&.[]('highlight_lines')) || []
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
      hash['attrs'] ||= {}
      hash['attrs']['line_numbers'] = @line_numbers if @line_numbers
      hash['attrs']['highlight_lines'] = @highlight_lines.join(',') if @highlight_lines&.any?
      hash
    end

    private

    def parse_highlight_lines(lines_str)
      return [] unless lines_str
      return lines_str if lines_str.is_a?(Array)

      lines_str.to_s.split(',').map(&:strip).map(&:to_i)
    end
  end
end
