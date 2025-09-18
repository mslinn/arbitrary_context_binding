require_relative '../lib/custom_binding'

# Example of mirroring instance variables between bindings
#
# After some experimentation, I realized nugem only needs
# CustomBinding.initialize, add_object_to_binding_as, and eval
# This code excersizes most methods in CustomBinding anyway.

# Test data
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

# Exercise all CustomBinding methods
def full_test
  puts 'full_test'
  custom_binding = CustomBinding::CustomBinding.new Foo.new

  # Create a new (internal) binding for the same object
  mirrored_binding = custom_binding.mirror_binding
  # Both original_binding and mirrored_binding are for the same object (obj).
  # Any changes to @foo via either binding are reflected in the other,
  # because they reference the same object’s instance variable.

  # Set or update the instance variable via the original binding
  custom_binding.eval '@foo = 100'
  puts '  custom_binding:   @foo = ' + custom_binding.eval('@foo').to_s # => 100
  puts '  mirrored_binding: @foo = ' + mirrored_binding.eval('@foo').to_s # => 100

  # Update the reference in the original binding via the new binding
  mirrored_binding.eval '@foo = 200'
  puts '  custom_binding:   @foo = ' + custom_binding.eval('@foo').to_s # => 200
  puts '  mirrored_binding: @foo = ' + mirrored_binding.eval('@foo').to_s # => 200

  # Add a new instance of Bar to the mirrored binding
  bar = Bar.new 'value of bar.bar'
  custom_binding.add_object_to_binding_as('@another', bar)
  puts '  custom_binding:   @another.bar = ' + custom_binding.eval('@another.bar') # => 'value of bar.bar'
  puts '  mirrored_binding: @another.bar = ' + mirrored_binding.eval('@another.bar') # => 'value of bar.bar'

  # Change the value via the original binding
  custom_binding.eval '@another.bar = "value of bar.bar changed"'
  puts '  mirrored_binding: @another.bar = ' + mirrored_binding.eval('@another.bar') # => 'value of bar.bar changed'

  # Ensure this still works:
  puts '  custom_binding:   @foo = ' + custom_binding.eval('@foo').to_s # => 200
  puts '  mirrored_binding: @foo = ' + mirrored_binding.eval('@foo').to_s # => 200
end

# Gets called in nugem_test
def hello = 'Hello from Mars'

# Just exercise those CustomBinding methods required by Nugem:
#  - CustomBinding.new
#  - CustomBinding#add_object_to_binding_as
#  - CustomBinding#eval
def nugem_test
  puts 'nugem_test'
  custom_binding = CustomBinding::CustomBinding.new binding # the current scope include the hello method

  bar = Bar.new 'value of bar.bar'
  custom_binding.add_object_to_binding_as('local_bar', bar)
  custom_binding.add_object_to_binding_as('@test_bar', bar)

  another_bar = Bar.new 'value of another_bar.bar'
  custom_binding.add_object_to_binding_as('@another_test_bar', another_bar)

  puts <<-END_MSG
  hello = #{custom_binding.eval('hello')}

  local_bar.tell_me_a_story         = #{custom_binding.eval('local_bar.tell_me_a_story')}
  @test_bar.tell_me_a_story         = #{custom_binding.eval('@test_bar.tell_me_a_story')}
  @another_test_bar.tell_me_a_story = #{custom_binding.eval('@another_test_bar.tell_me_a_story')}

  local_bar.bar         = #{custom_binding.eval('local_bar.bar')}
  @test_bar.bar         = #{custom_binding.eval('@test_bar.bar')}
  @another_test_bar.bar = #{custom_binding.eval('@another_test_bar.bar')}
  END_MSG
end

nugem_test
puts
full_test
