require 'dry/types/decorator'

module Dry
  module Types
    class Safe
      include Dry::Equalizer(:type, :options)
      include Decorator
      include Builder

      # @param [Object] input
      # @return [Object]
      def call(input)
        result = try(input)

        if result.respond_to?(:input)
          result.input
        else
          input
        end
      end
      alias_method :[], :call

      # @param [Object] input
      # @param [#call] block
      # @yieldparam [Failure] failure
      # @yieldreturn [Result]
      # @return [Result]
      def try(input, &block)
        type.try(input, &block)
      rescue TypeError, ArgumentError => e
        result = failure(input, e.message)
        block ? yield(result) : result
      end

      # @api public
      #
      # @see Definition#to_ast
      def to_ast
        [:safe, [type.to_ast]]
      end

      private

      # @param [Object, Dry::Types::Constructor] response
      # @return [Boolean]
      def decorate?(response)
        super || response.kind_of?(Constructor)
      end
    end
  end
end
