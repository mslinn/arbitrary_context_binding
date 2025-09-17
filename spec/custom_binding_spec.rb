require 'erb'

require_relative 'spec_helper'

class Foo
  def initialize
    @foo = 42
  end
end

# Another class to demonstrate adding an instance to the mirrored binding
class Bar
  attr_accessor :bar

  def initialize(bar)
    @bar = bar
  end

  def tell_me_a_story = 'A man was born. He lived, then died.'
end

module CustomBindingTest
  RSpec.describe CustomBinding do
    cb = custom_binding.mirror_binding
    cb.add_object_to_binding_as('@another', bar)

    describe 'using pre-existing instance variables' do
      it 'renders instance variable values from caller scope' do
        template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
        result = cb.render(template)
        expect(result).to eq('User: alice, Project: cool app')
      end
    end

    describe 'delegation from modules' do
      it 'delegates multiple methods from a module' do
        template = 'v=<%= version %>, h=<%= helper %>'
        result = cb.render(template)
        expect(result).to eq('v=9.9.9, h=helper called')
      end

      it 'delegates module methods with arguments' do
        template = "<%= greet('bob') %>"
        result = cb.render(template)
        expect(result).to eq('Hello, bob!')
      end

      it 'delegates module methods that take a block' do
        template = '<%= with_block { |x| x.upcase } %>'
        result = cb.render(template)
        expect(result).to eq('BLOCK ARG')
      end
    end

    describe 'delegation from objects' do
      it 'delegates methods from objects' do
        template = 'User: <%= user_name %>, Title: <%= title %>'
        result = cb.render(template)
        expect(result).to eq('User: alice, Title: cool app')
      end
    end

    context 'when no object responds' do
      it 'raises NameError with no matching method' do
        expect { cb.render('<%= baz %>') }.to raise_error(NameError)
      end
    end

    context 'with respond_to?' do
      it 'returns true for foo' do
        expect(cb.respond_to?(:foo)).to be true
      end

      it 'returns true for bar' do
        expect(cb.respond_to?(:bar)).to be true
      end

      it 'returns false for baz' do
        expect(cb.respond_to?(:baz)).to be false
      end
    end
  end
end
