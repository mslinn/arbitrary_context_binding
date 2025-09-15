require_relative 'spec_helper'

module ArbitraryContextBindingTest
  # ArbitraryContextBinding.provider_map value has this value: {
  #   :foo=>#<struct  foo="foo from obj1">, :foo==>#<struct  foo="foo from obj1">,
  #   :bar==>#<struct  bar="bar from obj2">, :bar=>#<struct  bar="bar from obj2">,
  #   :helper=>TestHelpers, :helper = TestHelpers, :greet = TestHelpers,
  #   :with_block = TestHelpers, :version = TestHelpers,
  #   :@__inspect_output = :base_binding, :@__memoized = :base_binding,
  #   :@repository = :base_binding, :@project = :base_binding
  # }

  RSpec.describe 'Shared context setup' do
    # include_context 'with arbitrary context binding setup'

    it 'defines repository and project' do
      expect(repository.user_name).to eq('alice')
      expect(project.title).to eq('cool app')
    end

    it 'provides obj1, obj2, and obj3 with expected values' do
      expect(obj1.foo).to eq('foo from obj1')
      expect(obj2.bar).to eq('bar from obj2')
      expect(obj3.foo).to eq('foo from obj3')
    end

    it 'creates acb_objects with repository and project' do
      template = 'User: <%= user_name %>, Title: <%= title %>'
      expect(acb_objects.render(template)).to eq('User: alice, Title: cool app')
    end

    it 'loads acb_module with TestHelpers' do
      template = 'v=<%= version %>, h=<%= helper %>'
      expect(acb_module.render(template)).to eq('v=9.9.9, h=helper called')
    end

    it 'loads acb12 from obj1' do
      expect(acb12.render('<%= foo %>')).to eq('foo from obj1')
    end

    it 'detects ambiguous methods in acb13' do
      expect { acb13.render('<%= foo %>') }
        .to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)
    end

    it 'initializes instance variables @repository and @project' do
      expect(@repository.user_name).to eq('alice')
      expect(@project.title).to eq('cool app')
    end

    it 'renders correctly with acb_all combining objects and modules' do
      puts acb_all.provider_for(:foo)
      puts acb_all.render('<%= foo %>')
      # foo is ambiguous (obj1  obj3), should raise
      expect { acb_all.render('<%= foo %>') }.to eq('asefd')
        .to raise_error(AmbiguousMethodError, /Ambiguous method 'foo'/)

      # bar is unique from obj2
      expect(acb_all.render('<%= bar %>')).to eq('bar from obj2')

      # module method
      expect(acb_all.render('<%= version %>')).to eq('9.9.9')
    end
  end
end
