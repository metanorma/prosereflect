# frozen_string_literal: true

module Prosereflect
  class Schema
    # Represents an edge in the content match graph
    class MatchEdge
      attr_reader :type, :next_match

      def initialize(type:, next_match:)
        @type = type
        @next_match = next_match
      end
    end

    # Represents a match state for node content expressions
    # Parses expressions like "block+", "inline*", "(paragraph | heading){2,4}"
    class ContentMatch
      attr_reader :valid_end, :next_edges, :wrap_cache

      def initialize(valid_end:, next_edges: [])
        @valid_end = valid_end
        @next_edges = next_edges
        @wrap_cache = [] # [[target_node_type, computed_wrapping]]
      end

      def self.empty
        @empty ||= new(valid_end: true, next_edges: [])
      end

      # Match a node type and return the next match state
      def match_type(node_type)
        @next_edges.find { |edge| edge.type == node_type }&.next_match
      end

      # Check if this match has inline content
      def inline_content?
        @next_edges.any? && @next_edges.first.type.is_a?(NodeType) && @next_edges.first.type.inline?
      end

      # Get the default type for this match (first non-text type without required attrs)
      def default_type
        @next_edges.each do |edge|
          type = edge.type
          if !type.text? && !type.has_required_attrs?
            return type
          end
        end
        nil
      end

      # Check if this content expression is compatible with another
      def compatible?(other)
        @next_edges.any? do |i|
          other.next_edges.any? { |j| i.type == j.type }
        end
      end

      # Fill in content before the given fragment
      # Returns a Fragment if successful, nil otherwise
      def fill_before(after:, to_end: false, start_index: 0)
        seen = [self]

        search = ->(match, types) do
          finished = match_fragment(after, start_index)
          if finished && (!to_end || finished.valid_end)
            return make_fragment(types)
          end

          match.next_edges.each do |edge|
            type = edge.type
            next_match = edge.next_match
            if !type.text? && !type.has_required_attrs? && !seen.include?(next_match)
              seen << next_match
              result = search.call(next_match, types + [type])
              return result if result
            end
          end
          nil
        end

        search.call(self, [])
      end

      # Find wrapping nodes to reach the target type
      def find_wrapping(target_node_type)
        cached = @wrap_cache.find { |entry| entry[0] == target_node_type }
        return cached[1] if cached

        computed = compute_wrapping(target_node_type)
        @wrap_cache << [target_node_type, computed]
        computed
      end

      # Number of edges
      def edge_count
        @next_edges.length
      end

      # Get edge at index n
      def edge(n)
        if n >= edge_count
          raise Prosereflect::SchemaErrors::ContentMatchError,
                "There's no #{n}th edge in this content match"
        end

        @next_edges[n]
      end

      # Match a fragment and return the next match state
      def match_fragment(fragment, start: 0, end_index: nil)
        end_index ||= fragment.content.size
        current = self
        i = start

        while current && i < end_index
          child = fragment[i]
          current = current.match_type(child.type)
          i += 1
        end
        current
      end

      # Parse content expression and return ContentMatch
      def self.parse(expression, node_types)
        return empty if expression.nil? || expression.empty?

        stream = TokenStream.new(expression, node_types)
        return empty if stream.peek.nil?

        expr = parse_expression(stream)
        unless stream.peek.nil?
          stream.error("Unexpected trailing text")
        end

        nfa_result = to_nfa(expr)
        dfa_result = to_dfa(nfa_result)
        check_for_dead_ends(dfa_result, stream)
        dfa_result
      end

      class << self
        private

        def parse_expression(stream)
          exprs = []
          loop do
            exprs << parse_sequence(stream)
            break unless stream.accept("|")
          end
          exprs.length == 1 ? exprs.first : { type: :choice, exprs: exprs }
        end

        def parse_sequence(stream)
          exprs = []
          loop do
            exprs << parse_subscript(stream)
            next_token = stream.peek
            break if next_token.nil? || next_token == ")" || next_token == "|"
          end
          exprs.length == 1 ? exprs.first : { type: :seq, exprs: exprs }
        end

        def parse_subscript(stream)
          expr = parse_atom(stream)
          loop do
            case stream.peek
            when "+"
              stream.advance
              expr = { type: :plus, expr: expr }
            when "*"
              stream.advance
              expr = { type: :star, expr: expr }
            when "?"
              stream.advance
              expr = { type: :opt, expr: expr }
            when "{"
              expr = parse_range(stream, expr)
            else
              break
            end
          end
          expr
        end

        def parse_range(stream, expr)
          stream.expect("{")
          min = stream.expect_number
          max = min

          if stream.accept(",")
            max = stream.peek == "}" ? -1 : stream.expect_number
          end
          stream.expect("}")

          { type: :range, min: min, max: max, expr: expr }
        end

        def parse_atom(stream)
          if stream.accept("(")
            expr = parse_expression(stream)
            stream.expect(")")
            expr
          elsif (token = stream.peek) && token =~ /^\w+$/
            stream.advance
            resolve_node_types(stream, token)
          else
            stream.error("Unexpected token \"#{stream.peek}\"")
          end
        end

        def resolve_node_types(stream, name)
          node_types = stream.node_types
          types = []

          if node_types.key?(name)
            types << node_types[name]
          else
            # Check groups
            node_types.each_value do |type|
              types << type if type.in_group?(name)
            end
          end

          stream.error("No node type or group \"#{name}\" found") if types.empty?

          if types.length == 1
            { type: :name, value: types.first }
          else
            { type: :choice, exprs: types.map { { type: :name, value: _1 } } }
          end
        end

        # Convert expression AST to NFA
        def to_nfa(expr)
          nfa = [[]] # Array of states, each state is array of edges
          start_state = 0

          # Use a marker for the terminal - we'll replace it later
          terminal_marker = :terminal

          compile_to_nfa(expr, start_state, terminal_marker, nfa)

          # Now replace terminal marker with actual terminal state at the end
          # Find and update any edges pointing to the marker
          actual_terminal_index = nfa.length
          nfa.each do |edges|
            edges.each do |edge|
              edge[:to] = actual_terminal_index if edge[:to] == terminal_marker
            end
          end
          # Add the terminal state
          nfa << []

          nfa
        end

        # Compile expression to NFA edges
        # The edges are returned with :to = target_state, ready to be added to nfa
        def compile_to_nfa(expr, from, target_state, nfa, terminal_state = nil)
          # If target_state is the terminal marker, use nfa.length (will be replaced later)
          # If target_state is nil, use nfa.length (next state to be allocated)
          # Otherwise use target_state directly
          actual_target = if target_state == :terminal
                            nfa.length
                          elsif target_state.nil?
                            nfa.length
                          else
                            target_state
                          end

          case expr[:type]
          when :choice
            expr[:exprs].flat_map do
              compile_to_nfa(_1, from, actual_target, nfa, terminal_state)
            end
          when :seq
            # Pass target_state (not actual_target) so compile_sequence knows about :terminal marker
            compile_sequence(expr[:exprs], from, target_state, nfa,
                             terminal_state)
          when :star
            loop_state = new_nfa_state(nfa)
            # Skip edge: from -> target (allows zero occurrences)
            skip_edge = { from: from, to: actual_target, term: nil }
            nfa[from] << skip_edge
            # Enter loop edge: from -> loop_state
            enter_edge = { from: from, to: loop_state, term: nil }
            nfa[from] << enter_edge
            # Compile inner expression at loop_state, targeting loop_state
            inner_edges = compile_to_nfa(expr[:expr], loop_state, loop_state,
                                         nfa, terminal_state)
            # Loopback edge: loop_state -> loop_state (epsilon)
            loop_edge = { from: loop_state, to: loop_state, term: nil }
            nfa[loop_state] << loop_edge
            # Exit edge: loop_state -> target (exit loop)
            # Compute exit_target at this moment since nfa may have grown
            exit_target = target_state == :terminal ? nfa.length : target_state
            exit_edge = { from: loop_state, to: exit_target, term: nil }
            nfa[loop_state] << exit_edge
            inner_edges
          when :plus
            # If target_state is :terminal, create our own loop_state for repetition
            # If target_state is a real state, use it as the loop_state (for use in sequences)
            loop_state = if target_state == :terminal
                           new_nfa_state(nfa)
                         else
                           target_state
                         end

            # Track if inner expression might set @last_loop_state (repetition constructs)
            inner_sets_loop = %i[plus star
                                 range].include?(expr[:expr][:type])

            # First edge: from -> loop_state via inner expression
            compile_to_nfa(expr[:expr], from, loop_state, nfa, terminal_state)

            # Self-loop edge: loop_state -> loop_state via the term (for repetition)
            # For :seq, use the first element's value as the term
            term_value = if expr[:expr][:type] == :seq && expr[:expr][:exprs].first[:type] == :name
                           expr[:expr][:exprs].first[:value]
                         elsif expr[:expr][:type] == :name
                           expr[:expr][:value]
                         elsif %i[plus star range].include?(expr[:expr][:type])
                           expr[:expr][:expr][:value]
                         end
            if term_value
              term_edge = { from: loop_state, to: loop_state, term: term_value }
              nfa[loop_state] << term_edge
            end
            # Exit edge: loop_state -> target (exit loop)
            exit_target = target_state == :terminal ? nfa.length : target_state
            exit_edge = { from: loop_state, to: exit_target, term: nil }
            nfa[loop_state] << exit_edge
            # Return loop_state so compile_sequence can update current_from
            # Only update if inner expression didn't set it (repetition constructs set it themselves)
            @last_loop_state = loop_state unless inner_sets_loop
            []
          when :opt
            # Skip edge: from -> target (allows zero)
            skip_edge = { from: from, to: actual_target, term: nil }
            nfa[from] << skip_edge
            # Inner expression edges: from -> target
            compile_to_nfa(expr[:expr], from, actual_target, nfa,
                           terminal_state)

          when :range
            compile_range(expr[:min], expr[:max], expr[:expr], from,
                          target_state, nfa, terminal_state)
          when :name
            edge = { from: from, to: actual_target, term: expr[:value] }
            nfa[from] << edge
            [edge]
          end
        end

        def compile_sequence(exprs, from, terminal_state, nfa, term_state = nil)
          results = []
          i = 0
          current_from = from
          while i < exprs.length
            if i == exprs.length - 1
              # Last element: use terminal as target
              edges = compile_to_nfa(exprs[i], current_from, terminal_state,
                                     nfa, term_state)
              results.concat(edges)
            else
              # For non-last elements, determine if we should use terminal_state directly
              # or allocate a new intermediate state.
              # At i=0 (first element), if terminal_state is a real state (not :terminal),
              # use it directly - the first element should target the loop_state.
              # For i>0, only reuse terminal_state if we're already at the loop_state
              # (terminal_state == current_from).
              use_terminal = (i.zero? && terminal_state != :terminal) ||
                (terminal_state != :terminal && terminal_state == current_from)

              if use_terminal
                # Use terminal_state as target
                saved_last_loop = @last_loop_state
                @last_loop_state = nil
                edges = compile_to_nfa(exprs[i], current_from, terminal_state,
                                       nfa, term_state)
                results.concat(edges)
                # After :plus, update current_from to loop_state
                current_from = @last_loop_state || terminal_state
              else
                # Allocate new intermediate state for this element
                next_from = new_nfa_state(nfa)
                saved_last_loop = @last_loop_state
                @last_loop_state = nil
                edges = compile_to_nfa(exprs[i], current_from, next_from, nfa,
                                       term_state)
                results.concat(edges)
                # After :plus, update current_from to loop_state
                current_from = @last_loop_state || next_from
              end
              @last_loop_state = saved_last_loop
            end
            i += 1
          end
          results
        end

        def compile_range(min, max, expr, from, target_state, nfa,
term_state = nil)
          results = []
          cur = from

          # Track if target_state was originally :terminal so we can always use
          # nfa.length at final edge time, not a stale resolved value
          target_is_terminal = target_state == :terminal || target_state.nil?
          # Resolve target_state to actual target for edges within this expression
          target_is_terminal ? nfa.length : target_state

          # Required repetitions
          min.times do
            next_state = new_nfa_state(nfa)
            edges = compile_to_nfa(expr, cur, next_state, nfa, term_state)
            # Edges are already added to nfa by compile_to_nfa
            results.concat(edges)
            cur = next_state
          end

          if max == -1
            # Unbounded: connect cur to loop_state via expr, then loop at loop_state with expr, with exit to target
            loop_state = new_nfa_state(nfa)
            # Connect cur to loop_state with expr (not loop_state to loop_state)
            edges = compile_to_nfa(expr, cur, loop_state, nfa, term_state)
            # Edges already added by compile_to_nfa
            results.concat(edges)
            # Create self-loop at loop_state using the expression term (allows staying in loop via expr)
            loop_edge = if expr[:type] == :name
                          { from: loop_state, to: loop_state,
                            term: expr[:value] }
                        else
                          # For complex expressions, create epsilon self-loop
                          { from: loop_state, to: loop_state, term: nil }
                        end
            nfa[loop_state] << loop_edge
            # Exit edge from loop_state to target
            exit_target = target_is_terminal ? nfa.length : target_state
            exit_edge = { from: loop_state, to: exit_target, term: nil }
            nfa[loop_state] << exit_edge
            results << exit_edge
            # Also add exit from cur directly to target (for when we stop after minimum)
            direct_exit_target = target_is_terminal ? nfa.length : target_state
            direct_exit = { from: cur, to: direct_exit_target, term: nil }
            nfa[cur] << direct_exit
          else
            # Bounded: create optional skips for additional repetitions
            (min...max).each do
              next_state = new_nfa_state(nfa)
              # Expr edge from cur to next_state
              edges = compile_to_nfa(expr, cur, next_state, nfa, term_state)
              # Edges already added by compile_to_nfa
              results.concat(edges)
              # Skip edge from cur to next_state (optional)
              skip_edge = { from: cur, to: next_state, term: nil }
              nfa[cur] << skip_edge
              results << skip_edge
              cur = next_state
            end
            # Final edge to target
            final_target = target_is_terminal ? nfa.length : target_state
            final_edge = { from: cur, to: final_target, term: nil }
            nfa[cur] << final_edge
            results << final_edge
          end

          results
        end

        def new_nfa_state(nfa)
          nfa << []
          nfa.length - 1
        end

        def connect_edges(edges, to)
          edges.each do |edge|
            edge[:to] = to
          end
        end

        # Convert NFA to DFA using subset construction
        def to_dfa(nfa_states)
          labeled = {}

          explore = ->(states) do
            key = states.sort.join(",")

            return labeled[key] if labeled.key?(key)

            out = [] # Array of [node_type, [next_state_indices]]

            states.each do |state_index|
              nfa_states[state_index].each do |edge|
                next unless edge[:term]

                term = edge[:term]
                to_states = null_from(nfa_states, edge[:to])

                existing = out.find { |e| e[0] == term }
                if existing
                  existing[1] |= to_states
                else
                  out << [term, to_states]
                end
              end
            end

            # Terminal state is the last state in the NFA
            terminal_index = nfa_states.length - 1
            state = new(valid_end: states.include?(terminal_index))
            labeled[key] = state

            out.each do |term, next_states|
              next_key = next_states.sort.join(",")
              next_state = labeled[next_key] || explore.call(next_states)
              state.next_edges << MatchEdge.new(type: term,
                                                next_match: next_state)
            end

            state
          end

          start_states = null_from(nfa_states, 0)
          explore.call(start_states)
        end

        # Compute epsilon closure (states reachable via null transitions)
        def null_from(nfa_states, state_index)
          result = [state_index] # Start with the state itself
          scan = ->(idx) do
            nfa_states[idx].each do |edge|
              next unless edge[:term].nil?

              to = edge[:to]
              unless result.include?(to)
                result << to
                scan.call(to)
              end
            end
          end
          scan.call(state_index)
          result.sort
        end

        def check_for_dead_ends(match, stream)
          work = [match]
          visited = []
          i = 0

          while i < work.length
            state = work[i]
            next if visited.include?(state.object_id)

            visited << state.object_id

            dead = !state.valid_end
            node_names = []

            state.next_edges.each do |edge|
              node = edge.type
              node_names << node.name

              # Text nodes are always generatable; other nodes are generatable if they have no required attrs
              if dead && (node.text? || !node.has_required_attrs?)
                dead = false
              end

              unless work.include?(edge.next_match)
                work << edge.next_match
              end
            end

            if dead
              stream.error(
                "Only non-generatable nodes (#{node_names.join(', ')}) in a required " \
                "position",
              )
            end

            i += 1
          end
        end
      end

      # For creating test fragments
      def make_fragment(types)
        return nil if types.empty?

        nodes = types.map(&:create_and_fill)
        return nil if nodes.any?(&:nil?)

        Fragment.new(nodes)
      end

      # Token stream for parsing content expressions
      class TokenStream
        attr_reader :string, :node_types

        def initialize(string, node_types)
          @string = string
          @node_types = node_types
          @pos = 0
          @tokens = tokenize(string)
        end

        def peek
          @tokens[@pos]
        end

        def advance
          @tokens[@pos]&.tap { @pos += 1 }
        end

        def accept(tok)
          if peek == tok
            @pos += 1
            true
          else
            false
          end
        end

        def expect(tok)
          unless accept(tok)
            raise Prosereflect::SchemaErrors::ContentMatchError,
                  "Expected #{tok}, got #{peek.inspect}"
          end

          true
        end

        def expect_number
          tok = peek
          unless /^\d+$/.match?(tok)
            raise Prosereflect::SchemaErrors::ContentMatchError,
                  "Expected number, got #{tok.inspect}"
          end

          advance.to_i
        end

        def error(message)
          raise Prosereflect::SchemaErrors::ContentMatchError,
                "#{message} (in content expression) \"#{@string}\""
        end

        private

        def tokenize(string)
          string.scan(/\w+|\W/).grep_v(/^\s+$/)
        end
      end
    end
  end
end
