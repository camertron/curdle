require 'parser/current'

module Curdle
  class RemoveSorbet < ::Parser::TreeRewriter
    def on_send(node)
      remove_extend(node, 'T::Sig') ||
        remove_extend(node, 'T::Generic') ||
        remove_extend(node, 'T::Helpers') ||
        remove_t_send(node) ||
        remove_abstract_bang(node)

      super
    end

    def on_block(node)
      remove_sig(node)
      super
    end

    def on_ivasgn(node)
      remove_let(node)
      super
    end

    def on_casgn(node)
      remove_let(node) ||
        remove_type_member(node) ||
        remove_type_alias(node)

      super
    end

    private

    def remove_extend(send_node, const_str)
      receiver, name, *args = *send_node
      return false unless receiver.nil? && name == :extend
      return false unless args.size == 1
      return false unless args.first.location.expression.is?(const_str)

      remove(
        include_surrounding_whitespace(
          send_node.location.expression
        )
      )

      true
    end

    def remove_sig(block_node)
      send_node, = *block_node
      receiver, name, *args = *send_node
      return false unless receiver.nil? && name == :sig && args.empty?

      remove(
        include_surrounding_whitespace(
          block_node.location.expression
        )
      )

      true
    end

    def remove_t_send(send_node)
      receiver, name = *send_node
      return false unless receiver && receiver.location.expression.is?('T')

      remove_cast(send_node) || remove_must(send_node)

      true
    end

    def remove_abstract_bang(send_node)
      receiver, name = *send_node
      return false unless receiver.nil? && name == :abstract!

      remove(
        include_surrounding_whitespace(
          send_node.location.expression
        )
      )

      true
    end

    def remove_cast(send_node)
      _, name, *args = *send_node
      return false unless name == :cast

      remove_method_call(send_node)
      remove_all_but_first_arg(send_node)

      true
    end

    def remove_must(send_node)
      _, name, *args = *send_node
      return false unless name == :must

      remove_method_call(send_node)

      true
    end

    def remove_let(asgn_node)
      case asgn_node.type
        when :ivasgn
          lhs_var, rhs = *asgn_node
        when :casgn
          _, lhs_var, rhs = *asgn_node
        else
          raise "Unexpected node type '#{asgn_node.type}'"
      end

      return false unless rhs
      return false unless rhs.type == :send

      receiver, name, *args = *rhs
      return false unless name == :let && receiver.location.expression.is?('T')

      if args.first.type == :ivar || args.first.type == :cvar
        rhs_var, = *args.first

        # Indicates the @ivar = T.let(@ivar, ...) pattern. The entire ivar
        # assignment statement can be removed
        if lhs_var == rhs_var
          remove(
            include_surrounding_whitespace(
              asgn_node.location.expression
            )
          )
        end
      else
        # indicates assigning the ivar to an actual value, in which case we
        # can just remove the let and all args except the first
        remove_method_call(rhs)
        remove_all_but_first_arg(rhs)
      end

      true
    end

    def remove_type_member(casgn_node)
      _, _const_name, value_node = *casgn_node
      return false unless value_node.type == :send

      receiver, name = *value_node
      return false unless receiver.nil? && name == :type_member

      remove(
        include_surrounding_whitespace(
          casgn_node.location.expression
        )
      )

      true
    end

    def remove_type_alias(casgn_node)
      _, _const_name, value_node = *casgn_node
      return false unless value_node.type == :block

      send_node, = *value_node
      receiver, name = *send_node
      return false unless receiver && receiver.location.expression.is?('T') && name == :type_alias

      remove(
        include_surrounding_whitespace(
          casgn_node.location.expression
        )
      )

      true
    end

    def remove_method_call(send_node)
      receiver, name = *send_node

      # remove receiver, dot, and method name
      remove(receiver.location.expression) if receiver
      remove(send_node.location.dot) if send_node.location.dot
      remove(send_node.location.selector)

      # remove enclosing parens
      remove(send_node.location.begin) if send_node.location.begin
      remove(send_node.location.end)   if send_node.location.end
    end

    def remove_all_but_first_arg(send_node)
      _, _, *args = *send_node
      first_arg_loc = args[0].location.expression
      remove(args[1].location.expression.with(begin_pos: first_arg_loc.end_pos))
    end

    def include_surrounding_whitespace(location)
      source = location.source_buffer.source
      start = source.rindex(/[^ \t]/, location.begin_pos - 1) + 1
      location = location.with(begin_pos: start)

      if m = source.match(/[ \t]*(?:\r?\n)*/, location.end_pos)
        location = location.with(end_pos: location.end_pos + m[0].size)
      end

      location
    end
  end
end
