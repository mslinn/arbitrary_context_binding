require_relative '../../lib/custom_binding'

module CustomBindingTest
  class TestBinding
    def say_hello   = 'Hello from Mars'
    def say_goodbye = 'Goodbye from Venus'

    def initialize
      @an_instance_variable = 1234
    end
  end

  # RSpec's crazy shenanegans around how let works mean that let declarations are not present
  # in the binding as instance variables
  class TestData
    attr_reader :cb

    Repository = Struct.new(:user_name)
    Project = Struct.new(:title)

    def initialize
      project = Project.new 'cool app'      # local variable in this binding
      @repository = Repository.new 'alice'  # instance variable in this binding

      @cb = CustomBinding.new TestBinding.new
      @cb.add_object_to_binding_as '@project', project        # instance variable in custom binding @cb
      @cb.add_object_to_binding_as '@repository', @repository # instance variable in custom binding @cb
    end
  end
end
