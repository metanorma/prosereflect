# frozen_string_literal: true

require_relative 'node'
require_relative 'list_item'

module Prosereflect
  # OrderedList class represents a numbered list in ProseMirror.
  class OrderedList < Node
    PM_TYPE = 'ordered_list'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :start, :integer
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

    def start=(value)
      @start = value
      self.attrs ||= {}
      attrs['start'] = value
    end

    def start
      @start || attrs&.[]('start') || 1
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

    # Update the order (1 for numerical, 'a' for alphabetical, etc.)
    def order=(order_value)
      self.attrs ||= {}
      attrs['order'] = order_value
    end

    # Get the order value
    def order
      attrs&.[]('order') || 1
    end

    # Get text content with proper formatting
    def text_content
      return '' unless content

      content.map { |item| item.respond_to?(:text_content) ? item.text_content : '' }.join("\n")
    end
  end
end
