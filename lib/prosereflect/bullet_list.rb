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
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def bullet_style=(style)
      @bullet_style = style
      self.attrs ||= {}
      attrs['bullet_style'] = style
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
  end
end
