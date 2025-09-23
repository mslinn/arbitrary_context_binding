# Nugem only requires:
#  - CustomBinding.new
#  - CustomBinding#add_object_to_binding_as
#  - CustomBinding#eval
require 'erb'

module CustomBinding
  class CustomBinding
    # Add objects to the internal Binding instance
    # @param object [Binding, Object] provides the seed for the internal binding.
    #        If a Binding is provided then changes made to it in this class will be visible in the originating code.
    # @param other_objects [Hash] name/value pairs of objects to mirror in the internal binding
    def initialize(object = TOPLEVEL_BINDING, other_objects = {})
      # get (internal) binding for any object
      @binding = object.instance_of?(Binding) ? object : object.instance_eval { binding }
      raise ArgumentError, "other_objects must be a Hash, but it was a #{other_objects.class.name}" \
        unless other_objects.instance_of?(Hash)

      other_objects.each { |k, v| add_object_to_binding_as k, v }
    end

    # The new_name prefix determines whether object will be a local, instance variable within the_binding,
    # or if it will be a global variable
    def add_object_to_binding_as(new_name, object)
      # ObjectSpace._id2ref retrieves the object by its id, which is globally available.
      @binding.eval "#{new_name} = ObjectSpace._id2ref(#{object.object_id})"
    end

    # Copy all class variables from the source binding's receiver's class/module to the target class/module.
    # @param source_binding [Binding] the binding whose receiver's class/module to copy from
    # @param target_class [Class, Module] the class/module to copy class variables to
    def copy_class_variables(target_class)
      source_klass = @binding.receiver.class
      source_klass.class_variables.each do |var|
        value = source_klass.class_variable_get(var)
        target_class.class_variable_set(var, value) # rubocop:disable Style/ClassVars
      end
    end

    # Copy all constants from the source binding's receiver's class/module to the target class/module.
    # @param source_binding [Binding] the binding whose receiver's class/module to copy from
    # @param target_class [Class, Module] the class/module to copy constants to
    def copy_constants(target_class)
      source_klass = @binding.receiver.class
      source_klass.constants(false).each do |const|
        value = source_klass.const_get(const)
        target_class.const_set(const, value) unless target_class.const_defined?(const, false)
      end
    end

    # @return result of evaluating the given statement, which can contain method calls and references to any type of variable
    def eval(statement)
      @binding.eval statement
    end

    # @return [String] compact representation of all definitions in @binding
    def inspect
      contents = binding_contents.map do |key, value|
        "#{key}: #{value}"
      end.join(', ')
      "#<CustomBinding #{object_id} { #{contents} }>"
    end

    # Create a new binding that reflects all instance variables and methods of the given source_binding.
    # Changes to instance variables via either binding are reflected in both.
    # Class variables can be accessed via the class/module of the receiver.
    # Global variables are always accessible via $ prefix, regardless of binding.
    # Changes to either binding will be visible in both bindings.
    # Note that local variables are not shared between bindings in Ruby.
    #
    # @param source_binding [Binding] the original binding
    # @return [Binding] a new binding for the same receiver as the source binding.
    def mirror_binding
      @binding.receiver.instance_eval { binding }
    end

    # @return result of rendering the given statement contained within <% %> tags,
    # swhich can contain method calls and references to any type of variable
    def render(statement)
      erb = ERB.new statement
      erb.render @binding
    end

    # @return [String] all definitions in @binding
    def to_s
      contents = binding_contents.map do |key, value|
        "#{key}: #{value.map(&:to_s).join(', ')}"
      end.join("\n  ")
      "#<CustomBinding #{object_id}\n  #{contents}\n>"
    end

    private

    # Report all variables (local, instance, class, global) and method names defined in the binding
    # that are not part of TOPLEVEL_BINDING.
    # Only methods defined in the receiver are reported; inherited methods are ignored.
    # @return [Hash] a hash with keys :class_vars, :instance_vars, :globals, :locals, :methods.
    def binding_contents(the_binding = @binding)
      class_vars = the_binding.receiver.class.class_variables

      top_globals = TOPLEVEL_BINDING.send :global_variables
      globals_filtered = global_variables.reject { |x| top_globals.include?(x) }

      instance_vars = the_binding.receiver.instance_variables

      locals = the_binding.local_variables.reject { |x| x == :_ }

      methods_filtered = the_binding.receiver.methods(false)

      result = {}
      result[:class_vars]    = class_vars if class_vars.any?
      result[:globals]       = globals_filtered if globals_filtered.any?
      result[:instance_vars] = instance_vars if instance_vars.any?
      result[:locals]        = locals if locals.any?
      result[:methods]       = methods_filtered if methods_filtered.any?
      result
    end
  end
end
