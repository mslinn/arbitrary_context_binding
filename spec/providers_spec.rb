require 'erb'

require_relative 'spec_helper'

# CustomBinding.provider_map value has this value: {
#   :foo=>#<struct  foo="foo from obj1">, :foo==>#<struct  foo="foo from obj1">,
#   :bar==>#<struct  bar="bar from obj2">, :bar=>#<struct  bar="bar from obj2">,
#   :helper=>TestHelpers, :helper = TestHelpers, :greet = TestHelpers,
#   :with_block = TestHelpers, :version = TestHelpers,
#   :@__inspect_output = :base_binding, :@__memoized = :base_binding,
#   :@repository = :base_binding, :@project = :base_binding
# }
module CustomBindingTest
  RSpec.describe TestData do
    x = described_class.new
    context 'with provider_for and providers_for' do
      it 'returns the correct provider for an unambiguous object method' do
        expect(x.acb12.provider_for(:foo)).to eq(x.obj1)
        expect(x.acb12.providers_for(:foo)).to eq([x.obj1])
      end

      it 'returns the correct provider for another unambiguous object method' do
        expect(x.acb12.provider_for(:bar)).to eq(x.obj2)
        expect(x.acb12.providers_for(:bar)).to eq([x.obj2])
      end

      it 'raises AmbiguousMethodError for an ambiguous method defined in an array of objects' do
        expect(x.acb13.providers_for(:foo)).to contain_exactly(x.obj1, x.obj3)
        expect { x.acb13.provider_for(:foo) }.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
      end

      it 'returns the correct provider for a module method' do
        expect(x.acb_module.provider_for(:version)).to eq(TestHelpers)
        expect(x.acb_module.providers_for(:version)).to eq([TestHelpers])
      end

      it 'raises AmbiguousMethodError for an ambiguous method defined in an array of modules' do
        expect(x.acb_modules.providers_for(:helper)).to contain_exactly(OtherHelpers, TestHelpers)
        expect { x.acb_modules.provider_for(:helper) }.to raise_error(AmbiguousMethodError, /Ambiguous method 'helper'/)
      end

      it 'returns :base_binding for pre-existing instance variables' do
        expect(x.acb_all.providers_for(:@repository)).to eq([:base_binding])
        expect(x.acb_all.provider_for(:@repository)).to eq(:base_binding)
      end

      it 'returns raises for an unknown method' do
        expect { x.acb12.provider_for(:baz) }.to raise_error(NameError, /baz is undefined/)
      end

      it 'returns [] for an unknown method' do
        expect(x.acb12.providers_for(:baz)).to eq([])
      end
    end

    context 'when integrated with render' do
      it 'tracks the provider for methods invoked during template rendering' do
        template = '<%= foo %> <%= bar %>'
        result = x.acb12.render(template)
        expect(result).to eq('foo from obj1 bar from obj2')

        # After rendering, provider_for should still identify sources
        expect(x.acb12.provider_for(:foo)).to eq(x.obj1)
        expect(x.acb12.provider_for(:bar)).to eq(x.obj2)
      end

      it 'tracks the provider for a module method used in a template' do
        template = '<%= version %>'
        result = x.acb_module.render(template)
        expect(result).to eq('9.9.9')

        expect(x.acb_module.provider_for(:version)).to eq(TestHelpers)
      end

      it 'tracks the provider for an instance variable from base binding' do
        template = '<%= x.repository.user_name %>'
        result = x.acb_all.render(template)
        expect(result).to eq('alice')

        expect(x.acb_all.provider_for(:x.repository)).to eq(:base_binding)
        expect(x.acb_all.providers_for(:x.repository)).to eq([:base_binding])
      end

      it 'returns all providers for ambiguous methods in templates' do
        expect do
          x.acb13.render('<%= foo %>')
        end.to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)

        # providers_for should list all responders even if render raised
        expect(x.acb13.providers_for(:foo)).to contain_exactly(x.obj1, x.obj3)
      end
    end
  end
end
