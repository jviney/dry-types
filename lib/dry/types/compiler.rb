module Dry
  module Types
    class Compiler
      attr_reader :registry

      def initialize(registry)
        @registry = registry
      end

      def call(ast)
        visit(ast)
      end

      def visit(node)
        method, *args = node
        send(:"visit_#{method}", *args)
      end

      def visit_constructor(node)
        definition, fn = node
        primitive = visit(definition)
        Types::Constructor.new(primitive, &fn)
      end

      def visit_safe(node)
        method, *args = node
        Types::Safe.new(send(:"visit_#{method}", *args))
      end

      def visit_definition(*node)
        primitive, meta = node
        definition = if registry.registered?(primitive)
                       registry[primitive]
                     else
                       Definition.new(primitive)
                     end
        meta.empty? ? definition : definition.meta(meta)
      end

      def visit_sum(node)
        node.map { |type| visit(type) }.reduce(:|)
      end

      def visit_array(node)
        registry['array'].member(call(node))
      end

      def visit_hash(node)
        constructor, schema = node
        Dry::Types['hash'].public_send(
          constructor,
          schema.map{ |key| visit(key) }.reduce({}, :merge)
        )
      end

      def visit_member(node)
        name, types = node
        { name => visit(types) }
      end
    end
  end
end
