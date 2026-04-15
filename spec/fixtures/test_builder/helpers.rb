# frozen_string_literal: true

# TestBuilder - Port of prosemirror-py test_builder/build.py
# Provides helpers for creating test nodes from string representations

module TestBuilder
  # Parse a test string into a document
  # Examples:
  #   TestBuilder.parse("doc(p(\"hello world\"))")
  #   TestBuilder.parse("doc(p(\"hello<|a> world\"))")
  def self.parse(str)
    builder = Builder.new
    builder.parse(str)
  end

  # Create a builder for a specific schema
  def self.for_schema(schema)
    Builder.new(schema: schema)
  end

  class Builder
    attr_reader :schema

    def initialize(schema: nil)
      @schema = schema
    end

    def parse(str)
      # Parse the string into a node tree
      # This is a simplified parser for test strings like:
      # doc(p("hello", em("world")))
      # doc(p("hello<|a> world"))
      content = extract_content(str)
      return nil if content.nil?

      parse_content(content)
    end

    def parse_content(str)
      # Simple recursive descent parser for test strings
      # Handles: doc(...), p(...), em(...), strong(...), etc.
      # And string literals: "hello world"
      tokens = tokenize(str)
      parse_tokens(tokens)
    end

    private

    def tokenize(str)
      # Simple tokenizer
      tokens = []
      i = 0
      while i < str.length
        case str[i]
        when /\s/
          i += 1
        when /[a-z_]/
          # Identifier
          start = i
          i += 1
          while i < str.length && str[i] =~ /[a-z0-9_]/
            i += 1
          end
          tokens << [:identifier, str[start...i]]
        when '"'
          # String literal
          i += 1
          start = i
          while i < str.length && str[i] != '"'
            i += 1
          end
          tokens << [:string, str[start...i]]
          i += 1 if i < str.length
        when "(", ")", "<", ">", "|", ","
          tokens << [str[i], str[i]]
          i += 1
        else
          i += 1
        end
      end
      tokens
    end

    def parse_tokens(tokens)
      return nil if tokens.empty?

      token = tokens.first
      return nil unless token

      if token[0] == :identifier
        name = token[1]
        tokens.shift
        consume("(", tokens)
        if name == "doc"
          children = parse_children(tokens)
          consume(")", tokens)
          build_doc(children)
        elsif name == "text"
          str_token = tokens.shift
          consume(")", tokens)
          build_text(str_token ? str_token[1] : "")
        else
          # Assume it's a paragraph or other node
          children = parse_children(tokens)
          consume(")", tokens)
          build_node(name, children)
        end
      elsif token[0] == :string
        tokens.shift
        build_text(token[1])
      end
    end

    def parse_children(tokens)
      children = []
      while tokens.any? && tokens.first[0] != ")"
        child = parse_tokens(tokens)
        children << child if child
        break if tokens.empty?

        if tokens.first[0] == ","
          tokens.shift
        end
      end
      children
    end

    def consume(expected, tokens)
      return if tokens.empty?

      token = tokens.first
      return unless token && token[0] == expected

      tokens.shift
    end

    def build_doc(children)
      nodes = children.flat_map do |child|
        if child.is_a?(Array)
          child
        else
          [child].compact
        end
      end
      Prosereflect::Document.new(content: nodes)
    end

    def build_node(type, children)
      case type
      when "p"
        content = children.flat_map do |child|
          if child.is_a?(Prosereflect::Node)
            [child]
          else
            []
          end
        end
        Prosereflect::Paragraph.new(content: content)
      when "text"
        children.first || ""
      else
        # Generic node - return children as content
        children.flatten.compact.first
      end
    end

    def build_text(str)
      return str if str.is_a?(String)

      Prosereflect::Text.new(text: str.to_s)
    end

    def extract_content(str)
      # Extract content between outermost parentheses
      paren_depth = 0
      start = nil
      str.each_char.with_index do |char, i|
        if char == "(" && paren_depth == 0
          start = i + 1
          paren_depth += 1
        elsif char == "("
          paren_depth += 1
        elsif char == ")"
          paren_depth -= 1
          if paren_depth == 0 && start
            return str[start...i]
          end
        end
      end
      nil
    end
  end

  # Extract position markers from a test string
  # Returns [content_string, positions_hash]
  # Example: "doc(p(\"hello<|a> world<|b>\"))" => ["doc(p(\"hello world\"))", {"a" => 6, "b" => 12}]
  def self.extract_markers(str)
    positions = {}
    marker_regex = /<\|([a-z0-9]+)>|<([0-9]+)>|<\|>/
    result = str.gsub(marker_regex) do |_match|
      if $1
        positions[$1] = $~.offset(0)[0]
      elsif $2
        positions[$2.to_i] = $~.offset(0)[0]
      else
        positions[:cursor] = $~.offset(0)[0]
      end
      ""
    end
    [result, positions]
  end
end
