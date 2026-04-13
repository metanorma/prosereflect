# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

`prosereflect` is a Ruby gem for parsing, manipulating, and traversing ProseMirror rich text editor document trees. It provides a Ruby object model over ProseMirror's JSON/YAML format with HTML import/export capabilities.

## Commands

```bash
# Install dependencies
bundle install

# Run tests and linting
rake

# Run tests only
rake spec

# Run a specific spec file
rspec spec/prosereflect/parser_spec.rb

# Run a specific test
rspec spec/prosereflect/parser_spec.rb:42

# Run linting only
rake rubocop
```

## Architecture

### Core Classes

- **Node** (`lib/prosereflect/node.rb`) - Base class for all document elements, extends `Lutaml::Model::Serializable`. All node types inherit `type`, `attrs`, `marks`, and `content` attributes.
- **Document** (`lib/prosereflect/document.rb`) - Top-level container, extends Node. Provides convenience methods like `tables`, `paragraphs`, `find_first`, `find_all`, `find_children`.
- **Parser** (`lib/prosereflect/parser.rb`) - Converts ProseMirror JSON/YAML hash structure into Node objects via `parse_document`.

### Node Hierarchy

All node types inherit from Node and define a `PM_TYPE` constant matching ProseMirror's type strings:
- Block nodes: `Document`, `Paragraph`, `Heading`, `Table`, `TableRow`, `TableCell`, `TableHeader`, `BulletList`, `OrderedList`, `ListItem`, `Blockquote`, `CodeBlockWrapper`, `CodeBlock`, `HorizontalRule`, `Image`, `HardBreak`
- Text nodes: `Text` with `Mark` collections (Bold, Italic, Code, Link, Strike, Subscript, Superscript, Underline)
- Special: `User` for @mentions

### HTML Conversion

- **Input::Html** (`lib/prosereflect/input/html.rb`) - Parses HTML strings into Document using Nokogiri
- **Output::Html** (`lib/prosereflect/output/html.rb`) - Converts Document back to HTML using Nokogiri::HTML::Builder

### Serialization

Uses `lutaml-model` for attribute serialization. The `key_value` block defines how Ruby attributes map to ProseMirror JSON keys. Override `to_h` methods handle special cases for attrs/marks serialization.

### Key Dependencies

- `lutaml-model` (~> 0.8) - Serialization framework
- `nokogiri` (~> 1.18) - HTML parsing/generation

## Superseding prosemirror-py

This library aims to be a full superset of the Python [prosemirror-py](https://github.com/metanorma/prosemirror-py). See `TODO.py-audit/` for detailed feature gap analysis and implementation plans to achieve complete compliance and schema validation parity.

## Data Model Pattern

```ruby
class SomeNode < Node
  PM_TYPE = 'some_node'

  attribute :custom_attr, :string

  key_value do
    map 'type', to: :type, render_default: true
    map 'attrs', to: :attrs
    map 'content', to: :content
  end
end
```
