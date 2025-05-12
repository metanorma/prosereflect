# frozen_string_literal: true

module Prosereflect
  class Node
    attr_reader :type, :attrs, :marks
    attr_accessor :content

    def initialize(data = {})
      @type = data['type']
      @attrs = data['attrs']
      @content = parse_content(data['content'])
      @marks = data['marks']
    end

    def parse_content(content_data)
      return [] unless content_data

      content_data.map { |item| Parser.parse(item) }
    end

    # Create a serializable hash representation of this node
    def to_h
      result = { 'type' => @type }
      result['attrs'] = @attrs if @attrs
      result['marks'] = @marks if @marks
      result['content'] = @content.map(&:to_h) unless @content.empty?
      result
    end

    # Add a child node to this node's content
    def add_child(node)
      @content ||= []
      @content << node
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

    # Create a node of the specified type with optional attributes
    def self.create(node_type, attrs = nil)
      node = new({ 'type' => node_type })
      node.instance_variable_set(:@attrs, attrs) if attrs
      node.instance_variable_set(:@content, [])
      node
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

    # Hard breaks should add a newline in text content
    def text_content_with_breaks
      content.map(&:text_content_with_breaks).join
    end
  end
end
