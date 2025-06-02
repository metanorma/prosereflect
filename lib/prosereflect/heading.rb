# frozen_string_literal: true

require_relative 'node'
require_relative 'text'

module Prosereflect
  class Heading < Node
    PM_TYPE = 'heading'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :level, :integer
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
      map 'marks', to: :marks
    end

    def initialize(params = {})
      super
      self.content ||= []

      # Extract level from attrs if provided
      return unless params[:attrs]

      @level = params[:attrs]['level']
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def level=(value)
      @level = value
      self.attrs ||= {}
      attrs['level'] = value
    end

    def level
      @level || attrs&.[]('level')
    end

    def text_content
      return '' unless content

      content.map(&:text_content).join
    end

    def add_text(text)
      text_node = Text.new(text: text)
      add_child(text_node)
      text_node
    end

    def to_h
      result = super
      result['attrs'] ||= {}
      result['attrs']['level'] = level if level
      result
    end
  end
end
