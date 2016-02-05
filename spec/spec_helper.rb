$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'dry-types'

begin
  require 'byebug'
rescue LoadError; end

Dir[Pathname(__dir__).join('shared/*.rb')].each(&method(:require))

RSpec.configure do |config|
  config.before do
    @types = Dry::Types.container._container.keys

    module Test
      def self.remove_constants
        constants.each { |const| remove_const(const) }
        self
      end
    end
  end

  config.after do
    container = Dry::Types.container._container
    (container.keys - @types).each { |key| container.delete(key) }
    Dry::Types.instance_variable_set('@type_map', ThreadSafe::Cache.new)

    Object.send(:remove_const, Test.remove_constants.name)
  end
end
