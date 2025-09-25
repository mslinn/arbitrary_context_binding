# Nugem only requires:
#  - CustomBinding.new
#  - CustomBinding#add_object_to_binding_as
#  - CustomBinding#eval
module CustomBinding
  class CustomBinding
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
  end
end
