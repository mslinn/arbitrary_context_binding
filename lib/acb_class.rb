require 'erb'

class AmbiguousMethodError < StandardError; end

# This class must be constructed *after* the binding, the objects, and the modules to be referenced
# have been constructed and are available.
#
# Provide a binding that resolves methods against an array of objects.
# Raise NameError if more than one object responds to the same method.
# Only public methods will be honored.
#
# Modules and classes can also contribute methods to delegation resolution.
#
# The internally constructed ERB provided by ArbitraryContextBinding#render can use:
#  - Instance vars: <%= @blah.user_name %>
#  - Delegated instance methods: <%= user_name %>
#  - Module and class methods: <%= Project.version %>
#  - Delegated module methods: <%= version %>
#
# ERB trim mode is set to '-'.
# See https://www.rubydoc.info/stdlib/erb/ERB#initialize-instance_method
#
# Unlike an approach that would use method_missing, the delegation approach used invokes real singleton methods
# created with define_singleton_method. This means the methods can be used with respond_to?
# and the code runs much faster.
#
# Ambiguous method references return true in response to respond_to?, but raise NameError when invoked.
# See the RSpec tests for further information.
#
# @example
# acb = ArbitraryContextBinding.new(objects: [obj1, obj2])
# expanded_template = acb.render template
# acb.provider_for(:method_name)  # => #<struct foo="obj1">
# acb.provider_for(:@blah)  # => :base_binding
module ArbitraryContextBinding
  class ArbitraryContextBinding
    attr_reader :base_binding, :modules, :objects

    # @param base_binding: is the binding to use as the base for this context binding.
    #                      This is typically the caller's binding so that instance variables
    #                      defined in the calling scope are accessible from ERB templates.
    # @param objects [Array]: are the objects whose public methods are copied into the ERB
    #                         (so you can write ERB templates like <%= obj.method %>).
    # @param modules [Array]: are copied into the ERB (so you can write ERB templates like <%= Project.version %>).
    #
    # objects and modules are passed by reference and are not shallow copies, so changes to module or object
    # definitions are honored.
    def initialize(base_binding: binding, modules: [], objects: [])
      raise ArgumentError, 'base_binding must be a Binding' unless base_binding.is_a? Binding
      raise ArgumentError, 'modules must be an Array' unless modules.is_a? Array
      raise ArgumentError, 'objects must be an Array' unless objects.is_a? Array

      @base_binding = base_binding
      @modules      = modules # .dup # shallow copy
      @objects      = objects # .dup # shallow copy
    end

    # Raises an exception if name is ambiguous
    def provider_for(name)
      result = providers_for(name)
      raise NameError, "#{name} is undefined" if result.empty?

      raise AmbiguousMethodError, "Ambiguous method '#{name}' is multiply defined in #{result}" unless result&.length == 1

      result.first
    end

    # Look up where name is defined
    # @param name [String, Symbol]
    # @return [:base_binding] if name is only defined there, or an array of providers, or [] if no definition found
    # Does not raise an exception if name is ambiguous
    def providers_for(name)
      result = (@objects + @modules).select { |provider| defined_in_object?(provider, name.to_s, name.to_sym) }
      result << :base_binding if symbol_defined_in_binding?(name)
      result
    end

    # Check a symbol for all possible definitions within the current binding, including local variables,
    # instance variables, class variables, constants, and methods.
    def symbol_defined_in_binding?(name_or_symbol)
      name, symbol = case name_or_symbol
                     when String
                       [name_or_symbol, name_or_symbol.to_sym]
                     when Symbol
                       [name_or_symbol.to_s, name_or_symbol]
                     else
                       puts "#{name_or_symbol} has an unexpected type: #{name_or_symbol.class.name}"
                     end
      return true if !name.to_s.start_with?('@') && @base_binding.local_variable_defined?(symbol)

      object = @base_binding.receiver # the object the current code is executing on (e.g., main or an instance).
      defined_in_object? object, name, symbol
    end

    # Indicate if a name/symbol is defined in the given object
    # @param object [Object] object to search
    # @param name [String] Name of method or variable to search for
    # @param symbol [Symbol] Symbol version of name
    # @return [Boolean] true iff name/symbol was found in the given object
    def defined_in_object?(object, name, symbol)
      return false if top_level_module_of(object) == 'RSpec' # Debugging tools are supposed to make things easier

      puts "      Examining #{object.inspect} for definition of #{name}"
      if object.respond_to?(symbol)
        puts "        Found method definition for #{name} in #{object.inspect}"
        return true
      end
      if name.start_with?('@') && object.instance_variable_defined?(symbol)
        puts "        Found instance variable definition for #{name} in #{object.inspect}"
        return true
      end
      # Cannot directly use `class_variable_defined?` on the receiver unless it's a class.
      # A more general approach is to check if the object's class has the class variable.
      if name.start_with?('@@') && object.class.class_variable_defined?(symbol)
        puts "        Found class variable definition for #{name} in #{object.inspect}"
        return true
      end

      begin
        if object.class.const_defined?(symbol)
          puts "        Found constant definition for #{name} in #{object.inspect}"
          return true
        end
      rescue NameError
        # The symbol is not a valid constant name, so do nothing.
      end

      false
    end

    # Render an ERB template string in the fully constructed context.
    # @param template [String] The ERB template to render.
    # @return [String] The rendered (expanded) template.
    def render(template)
      # For ERB (not necessarily with Rails), trim_mode: '-' removes one following newline:
      #  - the newline must be the first char after the > that ends the ERB expression
      #  - no following spaces are removed
      #  - only a single newline is removed
      erb = ERB.new template, trim_mode: '-'
      acb = ArbitraryContextBinding.new(base_binding: @base_binding, modules: @modules, objects: @objects)
      erb.result acb.the_binding
    rescue NameError => e
      puts e.message
      ''
    end

    # @return the caller’s binding so pre-existing instance variables are available
    def the_binding = @base_binding

    def to_string
      msg = 'ArbitraryContextBinding'
      msg += " #{@base_binding.local_variables.length} objects" if @base_binding.local_variables.any?
      msg += " #{@base_binding.instance_variables.length} objects" if @base_binding.instance_variables.any?
      msg += " #{@objects.length} objects" if @objects.any?
      msg += " #{@modules.length} objects" if @modules.any?
      msg
    end

    def top_level_module_of(object)
      object.class.to_s.split('::').first
    end

    # Order is important:
    alias inspect_original inspect # Call this if you need to
    alias to_s to_string
    def inspect = "#<#{to_string}>"
  end
end
