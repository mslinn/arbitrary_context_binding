require 'erb'

require_relative 'spec_helper'

module ArbitraryContextBinding
  class ArbitraryContextBindingTest
    RSpec.describe ArbitraryContextBinding do
      include_context 'with arbitrary context binding setup'

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
