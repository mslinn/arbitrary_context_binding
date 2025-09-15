require_relative '../lib/custom_binding'

# Example: Mirrored instance variable between bindings

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

# Get to work
obj = MyClass.new
original_binding = obj.instance_eval { binding } # this is how to get the (internal) binding for any object

# Create a new (internal) binding for the same object
new_binding = CustomBinding.mirror_binding(original_binding)
# Both original_binding and new_binding are for the same object (obj).
# Any changes to @foo via either binding are reflected in the other,
# because they reference the same object’s instance variable.

# Set or update the instance variable via the original binding
original_binding.eval '@foo = 100'
puts new_binding.eval '@foo' # => 100

# Update the reference in the original binding via the new binding
new_binding.eval '@foo = 200'
puts original_binding.eval '@foo' # => 200

# Add a new instance of AnotherClass to the mirrored binding
another_obj = AnotherClass.new 'value of another_obj.bar'
# ObjectSpace._id2ref retrieves the object by its id, which is globally available.
# new_binding.eval "@another = ObjectSpace._id2ref(#{another_obj.object_id})"
CustomBinding.add_object_to_binding_as('@another', another_obj, new_binding)
puts original_binding.eval '@another.bar' # => 'value of another_obj.bar'

# Change the value via the original binding
original_binding.eval '@another.bar = "changed"'
puts new_binding.eval '@another.bar' # => 'changed'

# Ensure this still works:
puts original_binding.eval '@foo' # => 200
