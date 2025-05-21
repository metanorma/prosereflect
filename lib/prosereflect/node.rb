# frozen_string_literal: true

require 'lutaml/model'
require_relative 'attribute'
require_relative 'mark'

module Prosereflect
  class Node < Lutaml::Model::Serializable
    PM_TYPE = 'node'

    attribute :type, :string
    attribute :attrs, :hash
    attribute :marks, Mark::Base, polymorphic: true, collection: true
    attribute :content, Node, polymorphic: true, collection: true

    key_value do
      map 'type', to: :type, render_default: true
      map 'attrs', to: :attrs
      map 'marks', to: :marks
      map 'content', to: :content
    end

    def initialize(data = nil, attrs = nil)
      if data.is_a?(String)
        super(type: data, attrs: attrs, content: [])
      elsif data.is_a?(Hash)
        # Handle marks in a special way to preserve expected behavior in tests
        if data['marks'] && data['marks'].is_a?(Array)
          marks_data = data['marks']
          data = data.dup
          data.delete('marks')
          super(data)
          self.marks = marks_data
        else
          super(data)
        end
      else
        super()
      end
    end

    def self.create(type = nil, attrs = nil)
      new(type || self::PM_TYPE, attrs)
    rescue NameError
      new(type || 'node', attrs)
    end

    # Convert to hash for serialization
    def to_h
      result = { "type" => type }

      if attrs && !attrs.empty?
        if attrs.is_a?(Hash)
          result["attrs"] = attrs
        elsif attrs.is_a?(Array) && attrs.all? { |attr| attr.respond_to?(:to_h) }
          # Convert array of attribute objects to a hash
          attrs_array = []
          attrs.each do |attr|
            if attr.is_a?(Prosereflect::Attribute::Base)
              attrs_array << attr.to_h
            else
              attrs_array << attr
            end
          end
          result["attrs"] = attrs_array unless attrs_array.empty?
        end
      end

      if marks && !marks.empty?
        result["marks"] = marks.map do |mark|
          if mark.is_a?(Hash)
            mark
          else
            mark.to_h
          end
        end
      end

      if content && !content.empty?
        result["content"] = content.map(&:to_h)
      end

      result
    end

    alias_method :to_hash, :to_h

    def marks=(value)
      if value.is_a?(Array)
        @marks = value.map do |v|
          if v.is_a?(Hash)
            Mark::Base.new(v)
          else
            v.is_a?(Mark::Base) ? v : Mark::Base.new(type: v.type)
          end
        end
      else
        super
      end
    end

    def parse_content(content_data)
      return [] unless content_data

      content_data.map { |item| Parser.parse(item) }
    end

    # Add a child node to this node's content
    def add_child(node)
      self.content ||= []
      content << node
      node
    end

    def find_first(node_type)
      return self if type == node_type

      return nil unless content

      content.each do |child|
        result = child.find_first(node_type)
        return result if result
      end
      nil
    end

    def find_all(node_type)
      results = []
      results << self if type == node_type

      if content
        content.each do |child|
          child_results = child.find_all(node_type)
          results.concat(child_results) if child_results
        end
      end

      results
    end

    def find_children(node_type)
      return [] unless content

      content.select { |child| child.is_a?(node_type) }
    end

    def text_content
      return '' unless content

      content.map(&:text_content).join
    end

    # Ensures YAML serialization outputs plain data instead of a Ruby object
    def to_yaml(*args)
      to_h.to_yaml(*args)
    end
  end
end
