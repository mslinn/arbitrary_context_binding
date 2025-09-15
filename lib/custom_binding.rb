module CustomBinding
  def self.add_object_to_binding_as(new_name, new_object, the_binding)
    the_binding.eval "#{new_name} = ObjectSpace._id2ref(#{new_object.object_id})"
  end

  # Copy all class variables from the source binding's receiver's class/module to the target class/module.
  # @param source_binding [Binding] the binding whose receiver's class/module to copy from
  # @param target_class [Class, Module] the class/module to copy class variables to
  def self.copy_class_variables(source_binding, target_class)
    source_klass = source_binding.receiver.class
    source_klass.class_variables.each do |var|
      value = source_klass.class_variable_get(var)
      target_class.class_variable_set(var, value) # rubocop:disable Style/ClassVars
    end
  end

  # Copy all constants from the source binding's receiver's class/module to the target class/module.
  # @param source_binding [Binding] the binding whose receiver's class/module to copy from
  # @param target_class [Class, Module] the class/module to copy constants to
  def self.copy_constants(source_binding, target_class)
    source_klass = source_binding.receiver.class
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
  def self.copy_local_variables(symbols, source_binding)
    new_binding = binding
    symbols.each do |sym|
      value = source_binding.local_variable_get(sym)
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
  # @param target_binding [Binding] the binding to assign the variable to
  def self.copy_variable_to_binding(var_name, value, target_binding)
    var_name = var_name.to_s
    case var_name
    when /^\$/ # global variable
      # Do nothing becaus globals are always visible
      # eval("#{var_name} = ObjectSpace._id2ref(#{value.object_id})", target_binding, __FILE__, __LINE__)
    when /^@@/ # class variable
      target_class = target_binding.receiver.class
      target_class.class_variable_set(var_name.to_sym, value) # rubocop:disable Style/ClassVars
    when /^@/ # instance variable
      target_binding.receiver.instance_variable_set(var_name.to_sym, value)
    else # local variable
      target_binding.local_variable_set(var_name.to_sym, value)
    end
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
  def self.mirror_binding(source_binding)
    source_binding.receiver.instance_eval { binding }
  end
end
