# frozen_string_literal: true

module Prosereflect
  class Text < Node
    PM_TYPE = "text"

    attribute :type, :string, default: -> {
      self.class.send(:const_get, "PM_TYPE")
    }
    attribute :text, :string, default: ""

    key_value do
      map "type", to: :type, render_default: true
      map "text", to: :text
      map "marks", to: :marks
    end

    def self.create(text = "", marks = nil)
      new(text: text, marks: marks)
    end

    def text_content
      text || ""
    end

    # Text node size is its character count. Text nodes carry no token of their
    # own, so splitting or merging a run is position-neutral.
    def node_size
      (text || "").length
    end

    # Text nodes are text nodes
    def text?
      true
    end

    def inline?
      true
    end

    # Return a copy of this text node with content restricted to range.
    # Carries attrs for the same reason copy does: splitting a run must not drop
    # attributes an AttrStep put on it.
    def cut(from = 0, to = nil)
      txt = text || ""
      to ||= txt.length
      self.class.new(text: txt[from...to], attrs: attrs, marks: raw_marks)
    end

    # A text node stores its string in `text`, not `content`, so the generic copy
    # would drop it. Preserve the string; new_content has no meaning for text.
    def copy(_new_content = nil, new_attrs = attrs, new_marks = raw_marks)
      self.class.new(text: text, attrs: new_attrs, marks: new_marks)
    end

    # Check equality with another text node
    def eq?(other)
      return false unless other.is_a?(self.class)

      text == other.text && to_h == other.to_h
    end

    # Override the to_h method to include the text attribute
    def to_h
      result = super
      result["text"] = text
      result
    end
  end
end
