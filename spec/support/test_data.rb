require_relative '../../lib/custom_binding'

module CustomBindingTest
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

  class TestData
    include CustomBinding

    attr_reader :acb, :acb12, :acb13, :cb_all, :cb_module, :cb_modules, :cb_object, :obj1, :obj2, :obj3, :project, :repository, :saved_binding

    # The contents the binding are a snapshot of the calling scope
    # RSpec's crazy shenanegans around how let works mean that let declarations are not present in the binding as instance variables
    # So regular instance variable declarations within a Module are used instead of let within a Class
    Repository = Struct.new(:user_name)
    Project = Struct.new(:title)

    def initialize
      # Changes to the binding will be reflected in @saved_binding, including new instance variables
      # Ruby looks ahead to declarations that have yet to be executed in the current scope and adds
      # local variables that will be defined into binding, with the value nil.
      @saved_binding = binding

      @repository = Repository.new 'alice'
      @project = Project.new 'cool app'

      @acb = CustomBinding.new @saved_binding

      @cb_objects = CustomBinding.new @saved_binding
      @cb_objects.add_object_to_binding_as '@project', @project
      @cb_objects.add_object_to_binding_as '@repository', @repository

      @obj1 = Struct.new(:foo).new('foo from obj1')
      @obj2 = Struct.new(:bar).new('bar from obj2')
      @obj3 = Struct.new(:foo).new('foo from obj3')

      @acb12 = CustomBinding.new @saved_binding
      @acb12.add_object_to_binding_as '@obj1', @obj1
      @acb12.add_object_to_binding_as '@obj2', @obj2

      @acb13 = CustomBinding.new @saved_binding
      @acb13.add_object_to_binding_as '@obj1', @obj1
      @acb13.add_object_to_binding_as '@obj3', @obj3

      @cb_all = CustomBinding.new @saved_binding
      @cb_all.add_object_to_binding_as '@obj1', @obj1
      @cb_all.add_object_to_binding_as '@obj2', @obj2
      @cb_all.add_object_to_binding_as '@obj3', @obj3
      @cb_all.add_object_to_binding_as '@project', @project
      @cb_all.add_object_to_binding_as '@repository', @repository
    end
  end
end
