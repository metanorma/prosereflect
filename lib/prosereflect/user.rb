# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  # User class represents a user mention in ProseMirror.
  class User < Node
    PM_TYPE = 'user'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }
    attribute :id, :string
    attribute :attrs, :hash

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'content', to: :content
    end

    def initialize(attributes = {})
      attributes[:content] = []
      super

      return unless attributes[:attrs]

      @id = attributes[:attrs]['id']
      self.attrs = { 'id' => @id }
    end

    def self.create(attrs = nil)
      new(attrs: attrs)
    end

    # Update the user ID
    def id=(user_id)
      @id = user_id
      self.attrs ||= {}
      attrs['id'] = user_id
    end

    def id
      @id || attrs&.[]('id')
    end

    # Override content-related methods since user mentions don't have content
    def add_child(*)
      raise NotImplementedError, 'User mention nodes cannot have children'
    end

    def content
      []
    end

    def to_h
      hash = super
      hash['attrs'] = {
        'id' => id
      }
      hash['content'] = []
      hash
    end
  end
end
