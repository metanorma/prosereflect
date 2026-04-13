# frozen_string_literal: true

module Prosereflect
  module Attribute
    autoload :Base, "#{__dir__}/attribute/base"
    autoload :Href, "#{__dir__}/attribute/href"
    autoload :Id, "#{__dir__}/attribute/id"
    autoload :Bold, "#{__dir__}/attribute/bold"
  end
end
