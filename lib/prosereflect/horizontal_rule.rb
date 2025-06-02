# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # HorizontalRule class represents a horizontal rule in ProseMirror.
  class HorizontalRule < Node
    PM_TYPE = 'horizontal_rule'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :style, :string
    attribute :width, :string
    attribute :thickness, :integer
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:content] = []
      super
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def style=(value)
      @style = value
      self.attrs ||= {}
      attrs['style'] = value
    end

    def style
      @style || attrs&.[]('style')
    end

    def width=(value)
      @width = value
      self.attrs ||= {}
      attrs['width'] = value
    end

    def width
      @width || attrs&.[]('width')
    end

    def thickness=(value)
      @thickness = value
      self.attrs ||= {}
      attrs['thickness'] = value
    end

    def thickness
      @thickness || attrs&.[]('thickness')
    end

    # Override content-related methods since horizontal rules don't have content
    def add_child(*)
      raise NotImplementedError, 'Horizontal rule nodes cannot have children'
    end

    def content
      []
    end
  end
end
