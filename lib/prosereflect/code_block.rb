# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # CodeBlock class represents a code block in ProseMirror.
  class CodeBlock < Node
    PM_TYPE = 'code_block'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :language, :string
    attribute :line_numbers, :boolean
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:attrs] ||= {
        'content' => nil,
        'language' => nil
      }
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def language=(value)
      @language = value
      self.attrs ||= {}
      attrs['language'] = value
    end

    def language
      @language || attrs&.[]('language')
    end

    def line_numbers=(value)
      @line_numbers = value
      self.attrs ||= {}
      attrs['line_numbers'] = value
    end

    def line_numbers
      @line_numbers || attrs&.[]('line_numbers') || false
    end

    def content=(value)
      @content = value
      self.attrs ||= {}
      attrs['content'] = value
    end

    def content
      @content || attrs&.[]('content')
    end

    attr_reader :highlight_lines_str

    def highlight_lines=(lines)
      @highlight_lines_str = if lines.is_a?(Array)
                               lines.join(',')
                             else
                               lines.to_s
                             end
    end

    def highlight_lines
      return [] unless @highlight_lines_str

      @highlight_lines_str.split(',').map(&:to_i)
    end

    def text_content
      content.to_s
    end

    def to_h
      hash = super
      hash['attrs'] = {
        'content' => content,
        'language' => language
      }
      hash['attrs']['line_numbers'] = line_numbers if line_numbers
      hash.delete('content')
      hash
    end

    # Get code block attributes as a hash
    def attributes
      {
        language: language,
        line_numbers: line_numbers,
        highlight_lines: highlight_lines
      }.compact
    end

    # Add a line of code
    def add_line(text)
      text_node = Text.new(text: text)
      add_child(text_node)
    end

    # Add multiple lines of code
    def add_lines(lines)
      lines.each { |line| add_line(line) }
    end

    private

    def normalize_content(content)
      lines = content.split("\n")
      return content if lines.empty?

      min_indent = lines.reject(&:empty?)
                        .map { |line| line[/^\s*/].length }
                        .min || 0

      normalized_lines = lines.map do |line|
        if line.empty?
          line
        else
          line[min_indent..] || ''
        end
      end

      normalized_lines.join("\n")
    end
  end
end
