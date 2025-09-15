require_relative '../../lib/arbitrary_context_binding'

module ArbitraryContextBindingTest
  module TestHelpers
    def self.version = '9.9.9'
    def self.helper  = 'helper called'
    def self.greet(name) = "Hello, #{name}!"

    def self.with_block
      yield 'block arg'
    end
  end

  module OtherHelpers
    def self.helper = 'other helper'
  end

  class ACBTestData
    include ArbitraryContextBinding

    attr_reader :acb, :acb12, :acb13, :acb_all, :acb_module, :acb_modules, :acb_object, :obj1, :obj2, :obj3, :project, :repository

    # The contents the binding are a snapshot of the calling scope
    # RSpec's crazy shenanegans around how let works mean that let declarations are not present in the binding as instance variables
    # So regular instance variable declarations within a Module are used instead of let within a Class
    Repository = Struct.new(:user_name)
    Project = Struct.new(:title)

    def initialize
      @acb = ArbitraryContextBinding.new

      @repository = Repository.new 'alice'
      @project = Project.new 'cool app'
      @acb_objects = ArbitraryContextBinding.new(objects: [@project, @repository])

      @obj1 = Struct.new(:foo).new('foo from obj1')
      @obj2 = Struct.new(:bar).new('bar from obj2')
      @obj3 = Struct.new(:foo).new('foo from obj3')
      @acb12 = ArbitraryContextBinding.new(objects: [@obj1, @obj2])
      @acb13 = ArbitraryContextBinding.new(objects: [@obj1, @obj3])

      @acb_module = ArbitraryContextBinding.new(modules: [TestHelpers])
      @acb_modules = ArbitraryContextBinding.new(modules: [OtherHelpers, TestHelpers])

      # Do not include obj3 because foo would be ambiguous
      @acb_all = ArbitraryContextBinding.new(
        objects:      [@obj1, @obj2, @project, @repository],
        modules:      [TestHelpers],
        base_binding: binding
      )
    end
  end
end
