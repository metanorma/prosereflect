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
  end
end
