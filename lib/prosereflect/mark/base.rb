# frozen_string_literal: true

module Prosereflect
  module Mark
    class Base < Lutaml::Model::Serializable
      PM_TYPE = "mark"

      attribute :type, :string, default: lambda {
        begin
          self.class.const_get(:PM_TYPE)
        rescue StandardError
          "mark"
        end
      }
      attribute :attrs, :hash

      key_value do
        map "type", to: :type, render_default: true
        map "attrs", to: :attrs
      end

      def self.create(attrs = nil)
        new(type: const_get(:PM_TYPE), attrs: attrs)
      rescue NameError
        new(type: "mark", attrs: attrs)
      end

      # Runtime mark-set operations (no schema exclusion or rank; see schema/mark.rb).
      # Schema::Mark#add_to_set is a separate implementation with different placement
      # rules, and the two cannot share code: its `type` is a MarkType carrying rank and
      # exclusions, while ours is a plain String. Rank is what orders a set there; here
      # the set keeps the order it was given, and a type it did not already hold goes
      # on the end.
      #
      # Nothing deduplicates marks on the way in -- Node#marks= maps the array it is
      # given without reordering or dropping any of it, and the parser forwards what it
      # parsed -- so adding a mark is what makes its own type unique, dropping every
      # other mark of that type. Other types are left exactly as they arrived, so this
      # does not make a whole set one-per-type on its own. The replacement takes the
      # position of the first mark it dropped rather than going last, because that
      # position is what lets an inverted replacement put the displaced mark back where
      # it was, and what merge_adjacent_text and the HTML writer both read. A set that
      # arrived holding two marks of one type loses the extras here, so undo restores
      # such a set only up to that collapse. Inserting at `index` is safe because
      # everything before the first same-type mark is a different type and so survives
      # `reject` at its original position.
      def add_to_set(set)
        index = set.index { |m| m.type == type }
        return set + [self] unless index

        set.reject { |m| m.type == type }.insert(index, self)
      end

      def remove_from_set(set)
        set.reject { |m| m == self }
      end

      # Same equality remove_from_set uses, so "in the set" and "removable" can
      # never disagree.
      def is_in_set?(set)
        set.any?(self)
      end

      # The first same-type mark, whose position add_to_set reuses, or nil when there is
      # none. Lives here so the rule stays next to the one that applies it.
      def displaced_from(set)
        set.find { |m| m.type == type }
      end

      # Convert to hash for serialization
      def to_h
        result = { "type" => type }
        result["attrs"] = attrs if attrs && !attrs.empty?
        result
      end

      # Override initialize to ensure the type is set correctly
      def initialize(options = {})
        super
        # Only set the type to PM_TYPE if no type was provided in options
        self.type = begin
          options[:type] || self.class.const_get(:PM_TYPE)
        rescue StandardError
          "mark"
        end
      end
    end
  end
end
