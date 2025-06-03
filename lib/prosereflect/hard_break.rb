# frozen_string_literal: true

require_relative 'node'

module Prosereflect
  class HardBreak < Node
    PM_TYPE = 'hard_break'

    attribute :type, :string, default: -> { send('const_get', 'PM_TYPE') }

    key_value do
      map 'type', to: :type, render_default: true
      map 'marks', to: :marks
    end

    def self.create(marks = nil)
      if marks.nil?
        new(type: PM_TYPE)
      else
        new(type: PM_TYPE, marks: marks)
      end
    end

    def initialize(data = nil)
      if data.is_a?(Hash)
        data = data.dup
        data['type'] = PM_TYPE
        marks_data = data.delete(:marks) || data.delete('marks')
        super(data)
        if marks_data.nil? || (marks_data.is_a?(Array) && marks_data.empty?)
          @marks = nil
        else
          self.marks = marks_data
        end
      else
        super({ type: PM_TYPE })
      end
    end

    def text_content
      "\n"
    end

    # Override to_h to handle marks properly
    def to_h
      result = super
      result.delete('marks') if marks.nil? || marks.empty?
      result
    end

    # Override marks= to handle mark objects properly
    def marks=(value)
      if value.nil?
        @marks = nil
      elsif value.is_a?(Array) && value.empty?
        @marks = []
      else
        super
      end
    end
  end
end
