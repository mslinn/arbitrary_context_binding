require_relative '../lib/binding'

# Example: Mirrored instance variable between bindings

# Test data
class MyClass
  def initialize
    @foo = 42
  end

  def get_binding
    binding
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
original_binding = obj.get_binding

# Create a new binding for the same object
new_binding = CustomBinding.mirrored_instance_binding(original_binding)

# Set or update the instance variable via the original binding
original_binding.eval('@foo = 100')
puts new_binding.eval('@foo') # => 100

# Update via the new binding
new_binding.eval('@foo = 200')
puts original_binding.eval('@foo') # => 200

# Add a new instance of AnotherClass to the mirrored binding
another_obj = AnotherClass.new('baz')
# ObjectSpace._id2ref retrieves the object by its id, which is globally available.
new_binding.eval("@another = ObjectSpace._id2ref(#{another_obj.object_id})")
puts original_binding.eval('@another.bar') # => 'baz'

# Change the value via the original binding
original_binding.eval('@another.bar = "changed"')
puts new_binding.eval('@another.bar') # => 'changed'

puts original_binding.eval('@foo') # => 200
