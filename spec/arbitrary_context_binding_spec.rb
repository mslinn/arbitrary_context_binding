require 'erb'

require_relative 'spec_helper'

module ArbitraryContextBindingTest
  RSpec.describe ArbitraryContextBinding do
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
  end
end
