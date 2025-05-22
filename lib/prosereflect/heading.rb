# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class Heading < Node
    PM_TYPE = 'heading'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'content', to: :content
      map 'attrs', to: :attrs
      map 'marks', to: :marks
    end

    def initialize(params = {})
      super
      self.content ||= []
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    def text_content
      return '' unless content

      content.map(&:text_content).join
    end
  end
end
