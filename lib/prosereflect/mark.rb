# frozen_string_literal: true

module Prosereflect
  module Mark
    autoload :Base, "#{__dir__}/mark/base"
    autoload :Bold, "#{__dir__}/mark/bold"
    autoload :Italic, "#{__dir__}/mark/italic"
    autoload :Code, "#{__dir__}/mark/code"
    autoload :Link, "#{__dir__}/mark/link"
    autoload :Strike, "#{__dir__}/mark/strike"
    autoload :Subscript, "#{__dir__}/mark/subscript"
    autoload :Superscript, "#{__dir__}/mark/superscript"
    autoload :Underline, "#{__dir__}/mark/underline"

    # Reconstruct a runtime mark from a serialized hash, mirroring Node#marks=.
    def self.from_h(hash)
      type = hash["type"] || hash[:type]
      attrs = hash["attrs"] || hash[:attrs]
      klass = begin
        const_get(type.to_s.capitalize, false)
      rescue NameError
        nil
      end
      klass && klass < Base ? klass.new(attrs: attrs) : Base.new(type: type, attrs: attrs)
    end
  end
end
