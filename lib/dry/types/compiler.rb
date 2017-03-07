module Dry
  module Types
    class Compiler
      attr_reader :registry

      HASH_TYPE_REGEX = %r[(.+)_(.+)].freeze

      def initialize(registry)
        @registry = registry
      end

      def call(ast)
        visit(ast)
      end

      def visit(node)
        method, *args = extract_method_and_args(node)
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

      def visit_hash(constructor, schema)
        merge_with('hash', constructor, schema)
      end

      def visit_member(node)
        name, types = node
        { name => visit(types) }
      end

      def merge_with(hash_id, constructor, schema)
        registry[hash_id].__send__(
          constructor, schema.first.map { |key| visit(key) }.reduce({}, :merge)
        )
      end

      def extract_method_and_args(node)
        method, *args = node
        if method.to_s.include?('hash')
          result = method.to_s.match(HASH_TYPE_REGEX)
          method, schema = result[1..2]
          args = args.unshift(schema)
        end
        [method, *args]
      end
    end
  end
end
