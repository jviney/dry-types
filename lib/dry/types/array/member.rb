module Dry
  module Types
    class Array < Definition
      class Member < Array
        # @return [Definition]
        attr_reader :member

        # @param [Class] primitive
        # @param [Hash] options
        # @option options [Definition] :member
        def initialize(primitive, options = {})
          @member = options.fetch(:member)
          super
        end

        # @param [Object] input
        # @param [Symbol] meth
        # @return [Array]
        def call(input, meth = :call)
          input.map { |el| member.__send__(meth, el) }
        end
        alias_method :[], :call

        # @param [Array, #all?] value
        # @return [Boolean]
        def valid?(value)
          super && value.all? { |el| member.valid?(el) }
        end

        # @param [Array, Object] input
        # @param [#call] block
        # @yieldparam [Failure] failure
        # @yieldreturn [Result]
        # @return [Result]
        def try(input, &block)
          if input.is_a?(::Array)
            result = call(input, :try)
            output = result.map(&:input)

            if result.all?(&:success?)
              success(output)
            else
              failure = failure(output, result.select(&:failure?))
              block ? yield(failure) : failure
            end
          else
            failure = failure(input, "#{input} is not an array")
            block ? yield(failure) : failure
          end
        end

        # @api public
        #
        # @see Definition#to_ast
        def to_ast
          [:array, [:member, [member.to_ast]]]
        end
      end
    end
  end
end
