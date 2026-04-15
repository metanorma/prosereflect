# frozen_string_literal: true

module Prosereflect
  # BulletList class represents an unordered list in ProseMirror.
  class BulletList < Node
    PM_TYPE = "bullet_list"

    attribute :type, :string, default: -> {
      self.class.send(:const_get, "PM_TYPE")
    }
    attribute :bullet_style, :string
    attribute :attrs, :hash

    key_value do
      map "type", to: :type, render_default: true
      map "attrs", to: :attrs
      map "content", to: :content
    end

    def initialize(attributes = {})
      attributes[:content] ||= []
      # Only apply default if attrs key is completely absent
      unless attributes.key?(:attrs) || attributes.key?("attrs")
        attributes[:attrs] = { "bullet_style" => nil }
      end
      super
    end

    # Use *args to distinguish between create (no args) and create(nil)
    # create with no args -> defaults applied
    # create(nil) from parser -> no defaults, attrs explicitly nil
    def self.create(*args)
      if args.empty?
        # No attrs provided - let initialize apply defaults
        new(type: PM_TYPE)
      else
        attrs = args[0]
        new({ type: PM_TYPE, attrs: attrs })
      end
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
      return "" unless content

      content.map do |item|
        item.respond_to?(:text_content) ? item.text_content : ""
      end.join("\n")
    end

    def bullet_style=(value)
      @bullet_style = value
      return if value.nil?

      self.attrs ||= {}
      attrs["bullet_style"] = value
    end

    def bullet_style
      @bullet_style || attrs&.[]("bullet_style")
    end
  end
end
