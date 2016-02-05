require 'spec_helper'

RSpec.describe Dry::Types do
  describe '.register' do
    it 'registers a new type constructor' do
      class FlatArray
        def self.constructor(input)
          input.flatten
        end
      end

      Dry::Types.register(
        'custom_array',
        Dry::Types::Type.new(FlatArray.method(:constructor), primitive: Array)
      )

      input = [[1], [2]]

      expect(Dry::Types['custom_array'][input]).to eql([1, 2])
    end
  end

  describe '.register_class' do
    it 'registers a class and uses `.new` method as default constructor' do
      module Test
        User = Struct.new(:name)
      end

      Dry::Types.register_class(Test::User)

      expect(Dry::Types['test.user'].primitive).to be(Test::User)
    end
  end

  describe '.[]' do
    it 'returns registered type for "string"' do
      expect(Dry::Types['string']).to be_a(Dry::Types::Type)
      expect(Dry::Types['string'].name).to eql('String')
    end

    it 'caches dynamically built types' do
      expect(Dry::Types['array<string>']).to be(Dry::Types['array<string>'])
    end
  end

  describe '.define_constants' do
    it 'defines types under constants in the provided namespace' do
      constants = Dry::Types.define_constants(Test, ['coercible.string'])

      expect(constants).to eql([Dry::Types['coercible.string']])
      expect(Test::Coercible::String).to be(Dry::Types['coercible.string'])
    end
  end

  describe '.finalize' do
    it 'defines all registered types under configured namespace' do
      Dry::Types.configure { |config| config.namespace = Test }
      Dry::Types.finalize

      expect(Test::Strict::String).to be(Dry::Types['strict.string'])
      expect(Test::Coercible::String).to be(Dry::Types['coercible.string'])
      expect(Test::Maybe::Coercible::Int).to be(Dry::Types['maybe.coercible.int'])
    end
  end
end
