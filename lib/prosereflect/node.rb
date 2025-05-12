# frozen_string_literal: true

require 'lutaml/model'
require_relative 'attribute'
require_relative 'mark'

module Prosereflect
  class Node < Lutaml::Model::Serializable
    attribute :type, :string
    attribute :attrs, Attribute::Base, polymorphic: true, collection: true
    attribute :marks, Mark::Base, polymorphic: true, collection: true
    attribute :content, Node, polymorphic: true, collection: true

    # def initialize(data = {})
    #   type = data['type']
    #   attrs = data['attrs']
    #   content = parse_content(data['content'])
    #   marks = data['marks']
    # end

    def parse_content(content_data)
      return [] unless content_data

      content_data.map { |item| Parser.parse(item) }
    end

    # Add a child node to this node's content
    def add_child(node)
      content ||= []
      content << node
      node
    end

    def find_first(node_type)
      return self if type == node_type

      content.each do |child|
        result = child.find_first(node_type)
        return result if result
      end
      nil
    end

    def find_all(node_type)
      results = []
      results << self if type == node_type
      content.each do |child|
        results.concat(child.find_all(node_type))
      end
      results
    end

    def find_children(node_type)
      content.select { |child| child.type == node_type }
    end

    def text_content
      content.map(&:text_content).join
    end
  end
end
