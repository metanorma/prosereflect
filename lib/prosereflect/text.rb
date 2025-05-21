# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class Text < Node
    PM_TYPE = 'text'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :text, :string, default: ''

    key_value do
      map 'type', to: :type, render_default: true
      map 'text', to: :text
      map 'marks', to: :marks
    end

    def self.create(text = '', marks = nil)
      new(text: text, marks: marks)
    end

    def text_content
      text || ''
    end

    # Override the to_h method to include the text attribute
    def to_h
      result = super
      result['text'] = text
      result
    end
  end
end
