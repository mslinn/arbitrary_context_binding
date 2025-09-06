require 'erb'
require 'optparse'

require_relative 'spec_helper'

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
    RSpec.describe ArbitraryContextBinding do
      let(:acb) { described_class.new }

      let(:repository_class) { Struct.new(:user_name) }
      let(:project_class)    { Struct.new(:title) }
      let(:repository)  { repository_class.new('alice') }
      let(:project)     { project_class.new('cool app') }
      let(:acb_objects) { described_class.new(objects: [repository, project]) }

      let(:obj1) { Struct.new(:foo).new('foo from obj1') }
      let(:obj2) { Struct.new(:bar).new('bar from obj2') }
      let(:obj3) { Struct.new(:foo).new('foo from obj3') }
      let(:acb12) { described_class.new(objects: [obj1, obj2]) }
      let(:acb13) { described_class.new(objects: [obj1, obj3]) }

      let(:acb_module) { described_class.new(modules: [TestHelpers]) }
      let(:acb_modules) { described_class.new(modules: [OtherHelpers, TestHelpers]) }

      obj = Struct.new(:helper).new('object helper')

      let(:acb_dup_method) { described_class.new(modules: [TestHelpers], objects: [obj]) }
      let(:acb_all) do
        described_class.new(
          objects:      [obj1, obj2, obj3],
          modules:      [TestHelpers],
          base_binding: binding
        )
      end

      before do # define pre-existing ivars in test scope
        @repository = repository
        @project    = project
      end

      describe 'using pre-existing instance variables' do
        it 'renders instance variable values from caller scope' do
          template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
          result = acb_all.render(template)
          expect(result).to eq('User: alice, Project: cool app')
        end
      end

      describe 'delegation from modules' do
        it 'delegates multiple methods from a module' do
          template = 'v=<%= version %>, h=<%= helper %>'
          result = acb_module.render(template)
          expect(result).to eq('v=9.9.9, h=helper called')
        end

        it 'delegates module methods with arguments' do
          template = "<%= greet('bob') %>"
          result = acb_module.render(template)
          expect(result).to eq('Hello, bob!')
        end

        it 'delegates module methods that take a block' do
          template = '<%= with_block { |x| x.upcase } %>'
          result = acb_module.render(template)
          expect(result).to eq('BLOCK ARG')
        end

        it 'raises if multiple modules define the same method' do
          template = '<%= helper %>'
          expect do
            acb_modules.render(template)
          end.to raise_error(AmbiguousMethodError, /Ambiguous method 'helper'/)
        end
      end

      describe 'delegation from objects' do
        it 'delegates methods from objects' do
          template = 'User: <%= user_name %>, Title: <%= title %>'
          result = acb_objects.render(template)
          expect(result).to eq('User: alice, Title: cool app')
        end
      end

      context 'when only one object responds' do
        it 'resolves foo from obj1' do
          expect(acb12.render('<%= foo %>')).to eq('foo from obj1')
        end

        it 'resolves bar from obj2' do
          expect(acb12.render('<%= bar %>')).to eq('bar from obj2')
        end
      end

      context 'when no object responds' do
        it 'raises NameError with no bindings' do
          expect { acb.render('<%= baz %>') }.to raise_error(NameError)
        end

        it 'raises NameError with no matching method' do
          expect { acb12.render('<%= baz %>') }.to raise_error(NameError)
        end
      end

      context 'when multiple objects and/or modules respond' do
        it 'raises NameError with ambiguity message' do
          expect do
            acb13.render('<%= foo %>')
          end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
        end

        it 'raises if a module and an object both respond to the same method' do
          obj = Struct.new(:helper).new('object helper')
          template = '<%= helper %>'

          expect do
            acb_dup_method.render(template)
          end.to raise_error(AmbiguousMethodError, /Ambiguous method 'helper'/)
        end
      end

      context 'with respond_to?' do
        it 'returns true for foo' do
          expect(acb12.respond_to?(:foo)).to be true
        end

        it 'returns true for bar' do
          expect(acb12.respond_to?(:bar)).to be true
        end

        it 'returns false for baz' do
          expect(acb12.respond_to?(:baz)).to be false
        end

        it 'defines foo but raises AmbiguousMethodError if more than one object defines the desired method' do
          expect(acb13.respond_to?(:foo)).to be true
          expect { acb13.foo }.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
        end
      end

      context 'with provider_for and providers_for' do
        it 'returns the correct provider for an unambiguous object method' do
          expect(acb12.provider_for(:foo)).to eq(obj1)
          expect(acb12.providers_for(:foo)).to eq([obj1])
        end

        it 'returns the correct provider for another unambiguous object method' do
          expect(acb12.provider_for(:bar)).to eq(obj2)
          expect(acb12.providers_for(:bar)).to eq([obj2])
        end

        it 'returns all providers for an ambiguous method' do
          expect(acb13.providers_for(:foo)).to contain_exactly(obj1, obj3)
          expect(acb13.provider_for(:foo)).to contain_exactly(obj1, obj3)
        end

        it 'returns the correct provider for a module method' do
          expect(acb_module.provider_for(:version)).to eq(TestHelpers)
          expect(acb_module.providers_for(:version)).to eq([TestHelpers])
        end

        it 'returns all providers for an ambiguous module method' do
          expect(acb_modules.providers_for(:helper)).to contain_exactly(OtherHelpers, TestHelpers)
          expect(acb_modules.provider_for(:helper)).to contain_exactly(OtherHelpers, TestHelpers)
        end

        it 'returns :base_binding for pre-existing instance variables' do
          expect(acb_all.provider_for(:@repository)).to eq(:base_binding)
          expect(acb_all.providers_for(:@repository)).to eq([:base_binding])
        end

        it 'returns nil and [] for an unknown method' do
          expect(acb12.provider_for(:baz)).to be_nil
          expect(acb12.providers_for(:baz)).to eq([])
        end
      end

      context 'when integrated with render' do
        it 'tracks the provider for methods invoked during template rendering' do
          template = '<%= foo %> <%= bar %>'
          result = acb12.render(template)
          expect(result).to eq('foo from obj1 bar from obj2')

          # After rendering, provider_for should still identify sources
          expect(acb12.provider_for(:foo)).to eq(obj1)
          expect(acb12.provider_for(:bar)).to eq(obj2)
        end

        it 'tracks the provider for a module method used in a template' do
          template = '<%= version %>'
          result = acb_module.render(template)
          expect(result).to eq('9.9.9')

          expect(acb_module.provider_for(:version)).to eq(TestHelpers)
        end

        it 'tracks the provider for an instance variable from base binding' do
          template = '<%= @repository.user_name %>'
          result = acb_all.render(template)
          expect(result).to eq('alice')

          expect(acb_all.provider_for(:@repository)).to eq(:base_binding)
          expect(acb_all.providers_for(:@repository)).to eq([:base_binding])
        end

        it 'returns all providers for ambiguous methods in templates' do
          expect do
            acb13.render('<%= foo %>')
          end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)

          # providers_for should list all responders even if render raised
          expect(acb13.providers_for(:foo)).to contain_exactly(obj1, obj3)
        end
      end
    end
  end
end
