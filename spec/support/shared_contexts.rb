# spec/support/shared_contexts.rb
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

module ArbitraryContextBinding
  class ArbitraryContextBindingTest
    RSpec.shared_context 'with arbitrary context binding setup' do
      let(:acb) { ArbitraryContextBinding.new }

      let(:repository_class) { Struct.new(:user_name) }
      let(:project_class)    { Struct.new(:title) }
      let(:repository)  { repository_class.new('alice') }
      let(:project)     { project_class.new('cool app') }
      let(:acb_objects) { ArbitraryContextBinding.new(objects: [repository, project]) }

      let(:obj1) { Struct.new(:foo).new('foo from obj1') }
      let(:obj2) { Struct.new(:bar).new('bar from obj2') }
      let(:obj3) { Struct.new(:foo).new('foo from obj3') }
      let(:acb12) { ArbitraryContextBinding.new(objects: [obj1, obj2]) }
      let(:acb13) { ArbitraryContextBinding.new(objects: [obj1, obj3]) }

      let(:acb_module) { ArbitraryContextBinding.new(modules: [TestHelpers]) }
      let(:acb_modules) { ArbitraryContextBinding.new(modules: [OtherHelpers, TestHelpers]) }

      let(:acb_all) do
        ArbitraryContextBinding.new(
          objects:      [obj1, obj2], # Do not include obj3 because foo would be ambiguous
          modules:      [TestHelpers],
          base_binding: binding
        )
      end

      before do # define pre-existing instance variables in the test scope
        @repository = repository
        @project    = project
      end
    end
  end
end
