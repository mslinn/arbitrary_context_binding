require_relative '../lib/acb_class'

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

module DefineStuff
  # include ArbitraryContextBinding

  repository_class = Struct.new(:user_name)
  project_class    = Struct.new(:title)

  @repository  = repository_class.new('alice')
  @project     = project_class.new('cool app')

  obj1 = Struct.new(:foo).new('foo from obj1')
  obj2 = Struct.new(:bar).new('bar from obj2')
  obj3 = Struct.new(:foo).new('foo from obj3')

  @acb_all = ArbitraryContextBinding.new(
    objects:      [obj1, obj2, obj3],
    modules:      [TestHelpers],
    base_binding: binding
  )

  def self.acb_all
    @acb_all
  end
end
