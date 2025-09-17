# Nugem only requires:
#  - CustomBinding.new
#  - CustomBinding#add_object_to_binding_as
#  - CustomBinding#eval
module CustomBinding
  class CustomBinding
    def initialize(object = TOPLEVEL_BINDING)
      @binding = object.instance_of?(Binding) ? object : object.instance_eval { binding } # get (internal) binding for any object
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

    # Copy specified local variables from a source binding to a new binding.
    # @param symbols [Array<Symbol>] the local variable names to transfer
    # @param source_binding [Binding] the binding to look up the variables in
    # @return [Binding] a new binding with the specified local variables set
    # @raise [NameError] if a symbol is not defined in the source binding
    def self.copy_local_variables(symbols)
      new_binding = binding
      symbols.each do |sym|
        value = @binding.local_variable_get(sym)
        new_binding.local_variable_set(sym, value)
      end
      new_binding
    end

    # Copy a variable (local, instance, class, or global) to a binding.
    #
    # The value provided by the binding after using this method will not automatically reflect subsequent changes in the
    # original binding for local, instance, or class variables.
    # - For local variables, this method copies the value at the time of the call.
    #   Later changes in the original binding will not be reflected.
    # - For instance and class variables, the method sets the value in the target binding's receiver.
    #   If the receiver is the same object as the original, changes will be reflected; if not, they won't.
    # - For global variables, since they are always accessible and shared, changes will be reflected everywhere.
    #
    # In summary, only if the target binding's receiver is the same object as the original will instance and class variable
    # changes be reflected. For local variables, changes are not reflected after copying.
    #
    # @param var_name [Symbol, String] the variable name (e.g., :foo, :@bar, :@@baz, :$qux)
    # @param value [Object] the value to assign
    # @param @binding [Binding] the binding to assign the variable to
    def self.copy_variable_to_binding(var_name, value)
      var_name = var_name.to_s
      case var_name
      when /^\$/ # global variable
        # Do nothing becaus globals are always visible
        # eval("#{var_name} = ObjectSpace._id2ref(#{value.object_id})", @binding, __FILE__, __LINE__)
      when /^@@/ # class variable
        target_class = @binding.receiver.class
        target_class.class_variable_set(var_name.to_sym, value) # rubocop:disable Style/ClassVars
      when /^@/ # instance variable
        @binding.receiver.instance_variable_set(var_name.to_sym, value)
      else # local variable
        @binding.local_variable_set(var_name.to_sym, value)
      end
    end

    # @return result of evaluating the given statement, which can contain method calls and references to any type of variable
    def eval(statement)
      @binding.eval statement
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

    # List all variables (local, instance, class, global) and method names defined in the binding.
    # @return [Hash] a hash with keys :locals, :instance_vars, :class_vars, :globals, :methods
    def list_binding_contents
      {
        locals:        @binding.local_variables,
        instance_vars: @binding.receiver.instance_variables,
        class_vars:    @binding.receiver.class.class_variables,
        globals:       global_variables,
        methods:       @binding.receiver.methods,
      }
    end

    def to_s
      contents = list_binding_contents.map do |key, value|
        "#{key}: #{value.inspect}"
      end.join(', ')
      "#<CustomBinding:#{object_id} binding=#{@binding.inspect} { #{contents} }>"
    end
  end
end
