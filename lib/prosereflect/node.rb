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
        if data[:marks] || data['marks']
          marks_data = data[:marks] || data['marks']
          data = data.dup
          data.delete('marks')
          data.delete(:marks)
          super(data)
          self.marks = marks_data
        else
          # Handle attrs properly
          if data[:attrs] || data['attrs']
            data = data.dup
            data[:attrs] = process_attrs_data(data[:attrs] || data['attrs'])
          end
          super(data)
        end
      else
        super()
      end
    end

    def process_attrs_data(attrs_data)
      if attrs_data.is_a?(Hash)
        attrs_data.transform_keys(&:to_s)
      else
        attrs_data
      end
    end

    def self.create(type = nil, attrs = nil)
      new(type || self::PM_TYPE, attrs)
    rescue NameError
      new(type || 'node', attrs)
    end

    # Convert to hash for serialization
    def to_h
      result = { 'type' => type }

      if attrs && !attrs.empty?
        if attrs.is_a?(Hash)
          result['attrs'] = process_node_attributes(attrs, type)
        elsif attrs.is_a?(Array) && attrs.all? { |attr| attr.respond_to?(:to_h) }
          # Convert array of attribute objects to a hash
          attrs_array = attrs.map do |attr|
            attr.is_a?(Prosereflect::Attribute::Base) ? attr.to_h : attr
          end
          result['attrs'] = attrs_array unless attrs_array.empty?
        end
      end

      if marks && !marks.empty?
        result['marks'] = marks.map do |mark|
          if mark.is_a?(Hash)
            mark
          elsif mark.respond_to?(:to_h)
            mark.to_h
          elsif mark.respond_to?(:type)
            { 'type' => mark.type.to_s }
          else
            raise ArgumentError, "Invalid mark type: #{mark.class}"
          end
        end
      end

      if content && !content.empty?
        result['content'] = if content.is_a?(Array)
                              content.map { |item| item.respond_to?(:to_h) ? item.to_h : item }
                            else
                              [content]
                            end
      end

      result
    end

    alias to_hash to_h

    def marks
      return nil if @marks.nil?
      return [] if @marks.empty?

      @marks.map do |mark|
        if mark.is_a?(Hash)
          mark
        elsif mark.respond_to?(:to_h)
          mark.to_h
        elsif mark.respond_to?(:type)
          { 'type' => mark.type.to_s }
        else
          raise ArgumentError, "Invalid mark type: #{mark.class}"
        end
      end
    end

    def raw_marks
      @marks
    end

    def marks=(value)
      if value.nil?
        @marks = nil
      elsif value.is_a?(Array) && value.empty?
        @marks = []
      elsif value.is_a?(Array)
        @marks = value.map do |v|
          if v.is_a?(Hash)
            type = v['type'] || v[:type]
            attrs = v['attrs'] || v[:attrs]
            begin
              mark_class = Prosereflect::Mark.const_get(type.to_s.capitalize)
              mark_class.new(attrs: attrs)
            rescue NameError
              Mark::Base.new(type: type, attrs: attrs)
            end
          elsif v.is_a?(Mark::Base)
            v
          elsif v.respond_to?(:type)
            begin
              mark_class = Prosereflect::Mark.const_get(v.type.to_s.capitalize)
              mark_class.new(attrs: v.attrs)
            rescue NameError
              Mark::Base.new(type: v.type, attrs: v.attrs)
            end
          else
            raise ArgumentError, "Invalid mark type: #{v.class}"
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

      content&.each do |child|
        child_results = child.find_all(node_type)
        results.concat(child_results) if child_results
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

    private

    def process_node_attributes(attrs, node_type)
      if attrs['attrs'].is_a?(Hash)
        attrs['attrs']
      elsif node_type == 'bullet_list' && attrs['bullet_style'].nil?
        nil
      else
        attrs
      end
    end
  end
end
