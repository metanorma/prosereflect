# frozen_string_literal: true

require "lutaml/model"

module Prosereflect
  class Error < StandardError; end

  autoload :Attribute, "prosereflect/attribute"
  autoload :Blockquote, "prosereflect/blockquote"
  autoload :BulletList, "prosereflect/bullet_list"
  autoload :CodeBlock, "prosereflect/code_block"
  autoload :CodeBlockWrapper, "prosereflect/code_block_wrapper"
  autoload :Document, "prosereflect/document"
  autoload :Fragment, "prosereflect/fragment"
  autoload :HardBreak, "prosereflect/hard_break"
  autoload :Heading, "prosereflect/heading"
  autoload :HorizontalRule, "prosereflect/horizontal_rule"
  autoload :Image, "prosereflect/image"
  autoload :Input, "prosereflect/input"
  autoload :ListItem, "prosereflect/list_item"
  autoload :Mark, "prosereflect/mark"
  autoload :Node, "prosereflect/node"
  autoload :OrderedList, "prosereflect/ordered_list"
  autoload :Output, "prosereflect/output"
  autoload :Paragraph, "prosereflect/paragraph"
  autoload :Parser, "prosereflect/parser"
  autoload :ResolvedPos, "prosereflect/resolved_pos"
  autoload :Table, "prosereflect/table"
  autoload :TableCell, "prosereflect/table_cell"
  autoload :TableHeader, "prosereflect/table_header"
  autoload :TableRow, "prosereflect/table_row"
  autoload :Text, "prosereflect/text"
  autoload :Transform, "prosereflect/transform"
  autoload :User, "prosereflect/user"
  autoload :VERSION, "prosereflect/version"
end
