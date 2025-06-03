# frozen_string_literal: true

require_relative 'node'
require_relative 'list_item'

module Prosereflect
  # BulletList class represents an unordered list in ProseMirror.
  class BulletList < Node
    PM_TYPE = 'bullet_list'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :bullet_style, :string
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      attributes[:attrs] ||= { 'bullet_style' => nil }
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def bullet_style=(value)
      @bullet_style = value
      self.attrs ||= {}
      attrs['bullet_style'] = value
    end

    def bullet_style
      @bullet_style || attrs&.[]('bullet_style')
    end

    def add_item(text)
      item = ListItem.new
      item.add_paragraph(text)
      add_child(item)
      item
    end

    def items
      return [] unless content

      content
    end

    # Add multiple items at once
    def add_items(items_content)
      items_content.each do |item_content|
        add_item(item_content)
      end
    end

    # Get item at specific position
    def item_at(index)
      return nil if index.negative?

      items[index]
    end

    # Get text content with proper formatting
    def text_content
      return '' unless content

      content.map { |item| item.respond_to?(:text_content) ? item.text_content : '' }.join("\n")
    end

    # Override to_h to exclude empty attrs
    def to_h
      hash = super
      hash['attrs'] ||= {}
      hash['attrs']['bullet_style'] = bullet_style
      hash
    end
  end
end
