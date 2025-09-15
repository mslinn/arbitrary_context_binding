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

# Excercise all methods
def full_test
  puts 'full_test'
  custom_binding = CustomBinding.new Foo.new

  # Create a new (internal) binding for the same object
  mirrored_binding = custom_binding.mirror_binding
  # Both original_binding and mirrored_binding are for the same object (obj).
  # Any changes to @foo via either binding are reflected in the other,
  # because they reference the same object’s instance variable.

  # Set or update the instance variable via the original binding
  custom_binding.eval '@foo = 100'
  puts custom_binding.eval '@foo' # => 100
  puts mirrored_binding.eval '@foo' # => 100

  # Update the reference in the original binding via the new binding
  mirrored_binding.eval '@foo = 200'
  puts custom_binding.eval '@foo' # => 200
  puts mirrored_binding.eval '@foo' # => 200

  # Add a new instance of Bar to the mirrored binding
  bar = Bar.new 'value of bar.bar'
  custom_binding.add_object_to_binding_as('@another', bar)
  puts custom_binding.eval '@another.bar' # => 'value of bar.bar'
  puts mirrored_binding.eval '@another.bar' # => 'value of bar.bar'

  # Change the value via the original binding
  custom_binding.eval '@another.bar = "value of bar.bar changed"'
  puts mirrored_binding.eval '@another.bar' # => 'value of bar.bar changed'

  # Ensure this still works:
  puts custom_binding.eval '@foo' # => 200
  puts mirrored_binding.eval '@foo' # => 200
end

def show(variable)
  puts "#{variable} = #{custom_binding.eval variable}"
end

# Just excercise those methods required by Nugem
def nugem_test
  puts 'nugem_test'
  custom_binding = CustomBinding.new TOPLEVEL_BINDING

  bar = Bar.new 'value of bar.bar'
  custom_binding.add_object_to_binding_as('@test_bar', bar)

  another_bar = Bar.new 'value of another_bar.bar'
  custom_binding.add_object_to_binding_as('@another_test_bar', another_bar)

  puts 'local_bar.tell_me_a_story' + custom_binding.eval('local_bar.tell_me_a_story')
  puts '@test_bar.bar = ' + custom_binding.eval('@test_bar.bar') # => "value of bar.bar"
  puts '@another_test_bar.bar = ' + custom_binding.eval('@another_test_bar.bar') # => "value of another_bar.bar"
  puts 'local_bar.bar = ' + custom_binding.eval('local_bar.bar') # => "value of bar.bar"
end

nugem_test
puts
full_test
