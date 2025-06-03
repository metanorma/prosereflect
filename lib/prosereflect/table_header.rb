# frozen_string_literal: true

require_relative 'table_cell'

module Prosereflect
  # TableHeader class represents a header cell in a table (<th> tag).
  # It inherits from TableCell but adds header-specific attributes.
  class TableHeader < TableCell
    PM_TYPE = 'table_header'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :scope, :string  # row, col, rowgroup, or colgroup
    attribute :abbr, :string   # abbreviated version of content
    attribute :colspan, :integer # number of columns this header spans

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      super
    end

    def self.create(attrs = nil)
      new(type: PM_TYPE, attrs: attrs, content: [])
    end

    # Add text to the last paragraph, or create a new one if none exists
    def add_text(text, marks = nil)
      last_paragraph = content&.last
      last_paragraph = add_paragraph if !last_paragraph || !last_paragraph.is_a?(Paragraph)
      last_paragraph.add_text(text, marks)
      self
    end

    # Set the scope of the header (row, col, rowgroup, or colgroup)
    def scope=(scope_value)
      return unless %w[row col rowgroup colgroup].include?(scope_value)

      self.attrs ||= {}
      attrs['scope'] = scope_value
    end

    def scope
      attrs&.[]('scope')
    end

    # Set abbreviated version of the header content
    def abbr=(abbr_text)
      self.attrs ||= {}
      attrs['abbr'] = abbr_text
    end

    def abbr
      attrs&.[]('abbr')
    end

    # Set the number of columns this header spans
    def colspan=(span)
      return unless span.to_i.positive?

      self.attrs ||= {}
      attrs['colspan'] = span.to_i
    end

    def colspan
      attrs&.[]('colspan')
    end

    # Get header attributes as a hash
    def header_attributes
      {
        scope: scope,
        abbr: abbr,
        colspan: colspan
      }.compact
    end

    # Override to_h to exclude nil attributes
    def to_h
      result = super
      if result['attrs']
        result['attrs'].reject! { |_, v| v.nil? }
        result.delete('attrs') if result['attrs'].empty?
      end
      result
    end
  end
end
