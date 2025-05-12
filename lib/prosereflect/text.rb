# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class Text < Node
    PM_TYPE = 'text'

    attribute :text, :string

    def text_content
      text || ''
    end
  end
end
