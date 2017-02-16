require 'dry/types/decorator'
require 'dry/types/constraints'
require 'dry/types/constrained/coercible'

module Dry
  module Types
    class Constrained
      include Dry::Equalizer(:type, :options, :rule)
      include Decorator
      include Builder

      # @return [Dry::Logic::Rule]
      attr_reader :rule

      # @param [Definition] type
      # @param [Hash] options
      def initialize(type, options)
        super
        @rule = options.fetch(:rule)
      end

      # @param [Object] input
      # @return [Object]
      # @raise [ConstraintError]
      def call(input)
        try(input) do |result|
          raise ConstraintError.new(result, input)
        end.input
      end
      alias_method :[], :call

      # @param [Object] input
      # @param [#call] block
      # @yieldparam [Failure] failure
      # @yieldreturn [Result]
      # @return [Result]
      def try(input, &block)
        result = rule.(input)

        if result.success?
          type.try(input, &block)
        else
          failure = failure(input, result)
          block ? yield(failure) : failure
        end
      end

      # @param [Object] value
      # @return [Boolean]
      def valid?(value)
        rule.(value).success? && type.valid?(value)
      end

      # @param [Hash] options
      #   The options hash provided to {Types.Rule} and combined
      #   using {&} with previous {#rule}
      # @return [Constrained]
      # @see Dry::Logic::Operators#and
      def constrained(options)
        with(rule: rule & Types.Rule(options))
      end

      # @return [true]
      def constrained?
        true
      end

      # @api public
      #
      # @see Definition#to_ast
      def to_ast
        [:constrained, [type.to_ast, rule.to_ast]]
      end

      private

      # @param [Object] response
      # @return [Boolean]
      def decorate?(response)
        super || response.kind_of?(Constructor)
      end
    end
  end
end
