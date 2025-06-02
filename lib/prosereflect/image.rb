# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # Image class represents a ProseMirror image node.
  # It handles image attributes like src, alt, title, dimensions, etc.
  class Image < Node
    PM_TYPE = 'image'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :src, :string
    attribute :alt, :string
    attribute :title, :string
    attribute :width, :integer
    attribute :height, :integer
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
    end

    def initialize(attributes = {})
      # Images don't have content, they're self-contained
      attributes[:content] = []

      # Extract attributes from the attrs hash if provided
      if attributes[:attrs]
        @src = attributes[:attrs]['src']
        @alt = attributes[:attrs]['alt']
        @title = attributes[:attrs]['title']
        @width = attributes[:attrs]['width']
        @height = attributes[:attrs]['height']
      end

      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    # Update the image source URL
    def src=(src_url)
      @src = src_url
      self.attrs ||= {}
      attrs['src'] = src_url
    end

    # Update the alt text
    def alt=(alt_text)
      @alt = alt_text
      self.attrs ||= {}
      attrs['alt'] = alt_text
    end

    # Update the title (tooltip)
    def title=(title_text)
      @title = title_text
      self.attrs ||= {}
      attrs['title'] = title_text
    end

    # Update the width
    def width=(value)
      @width = value
      self.attrs ||= {}
      attrs['width'] = value
    end

    # Update the height
    def height=(value)
      @height = value
      self.attrs ||= {}
      attrs['height'] = value
    end

    # Update dimensions (width and height)
    def dimensions=(dimensions)
      width, height = dimensions
      self.width = width if width
      self.height = height if height
    end

    # Get image attributes as a hash
    def image_attributes
      {
        src: src,
        alt: alt,
        title: title,
        width: width,
        height: height
      }.compact
    end

    # Override content-related methods since images don't have content
    def add_child(*)
      raise NotImplementedError, 'Image nodes cannot have children'
    end

    def content
      []
    end

    def src
      @src || attrs&.[]('src')
    end

    def alt
      @alt || attrs&.[]('alt')
    end

    def title
      @title || attrs&.[]('title')
    end

    def width
      @width || attrs&.[]('width')
    end

    def height
      @height || attrs&.[]('height')
    end
  end
end
