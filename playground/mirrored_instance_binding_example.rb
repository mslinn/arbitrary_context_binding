require_relative '../lib/custom_binding'

# Example of mirroring instance variables between bindings
#
# After some experimentation, I realized nugem only needs
# CustomBinding.initialize, add_object_to_binding_as, and eval
# This code excersizes most methods in CustomBinding anyway.

# Test data
class MyClass
  def initialize
    @foo = 42
  end
end

# Another class to demonstrate adding an instance to the mirrored binding
class AnotherClass
  attr_accessor :bar

  def initialize(bar)
    @bar = bar
  end
end

def full_test
  custom_binding = CustomBinding.new MyClass.new

  # Create a new (internal) binding for the same object
  new_binding = custom_binding.mirror_binding
  # Both original_binding and new_binding are for the same object (obj).
  # Any changes to @foo via either binding are reflected in the other,
  # because they reference the same object’s instance variable.

  # Set or update the instance variable via the original binding
  custom_binding.eval '@foo = 100'
  puts new_binding.eval '@foo' # => 100

  # Update the reference in the original binding via the new binding
  new_binding.eval '@foo = 200'
  puts custom_binding.eval '@foo' # => 200

  # Add a new instance of AnotherClass to the mirrored binding
  another_obj = AnotherClass.new 'value of another_obj.bar'
  custom_binding.add_object_to_binding_as('@another', another_obj)
  puts custom_binding.eval '@another.bar' # => 'value of another_obj.bar'

  # Change the value via the original binding
  custom_binding.eval '@another.bar = "value of another_obj.bar changed"'
  puts new_binding.eval '@another.bar' # => 'value of another_obj.bar changed'

  # Ensure this still works:
  puts custom_binding.eval '@foo' # => 200
  puts new_binding.eval '@foo' # => 200
end

def nugem_test
  custom_binding = CustomBinding.new TOPLEVEL_BINDING

  obj = AnotherClass.new 'value of obj.bar'
  custom_binding.add_object_to_binding_as('@obj', obj)

  another_obj = AnotherClass.new 'value of another_obj.bar'
  custom_binding.add_object_to_binding_as('@another', another_obj)

  puts custom_binding.eval '@foo' # => 200
  # puts new_binding.eval '@another.foo' # => 200
end

nugem_test
# full_test
