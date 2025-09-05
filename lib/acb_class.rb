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
#  - Instance vars: <%= @repository.user_name %>
#  - Delegated instance methods: <%= user_name %>
#  - Module and class methods: <%= Project.version %>
#  - Delegated module methods: <%= version %>
#
# ERB trim mode is set to '-'.
# See https://www.rubydoc.info/stdlib/erb/ERB#initialize-instance_method
#
# Unlike an approach that uses method_missing, the delegation approach used invokes real singleton methods
# created with define_singleton_method. This means the methods can be used with respond_to?
# and the code runs much faster.
#
# Ambiguous method references return true in response to respond_to?, but raise NameError when invoked.
# See the RSpec tests for further information.
#
# @example
# acb = ArbitraryContextBinding.new(objects: [obj1, obj2])
# expanded_template = acb.render template
module ArbitraryContextBinding
  class ArbitraryContextBinding
    attr_reader :base_binding, :modules, :objects

    # @param base_binding: is the binding to use as the base for this context binding.
    #                      This is typically the caller's binding so that instance variables
    #                      defined in the caller are visible inside ERB templates.
    # @param objects [Array]: are the objects whose public methods are copied into the ERB
    #                         (so you can call obj.method, etc.).
    # @param modules [Array]: are copied into the ERB (so you can call Project.version, etc.).
    def initialize(base_binding: binding, objects: [], modules: [])
      raise ArgumentError, 'base_binding must be a Binding' unless base_binding.is_a? Binding
      raise ArgumentError, 'objects must be an Array' unless objects.is_a? Array
      raise ArgumentError, 'modules must be an Array' unless modules.is_a? Array

      @objects = objects.dup # shallow copy
      @modules = modules.dup # shallow copy
      @base_binding = base_binding
      define_module_constants!
      define_delegators!
    end

    # @return the caller’s binding so pre-existing instance variables are available
    def the_binding = @base_binding

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
    end

    def to_string
      msg = 'ArbitraryContextBinding'
      msg += " #{@base_binding.local_variables.length} objects" if @base_binding.local_variables.any?
      msg += " #{@base_binding.instance_variables.length} objects" if @base_binding.instance_variables.any?
      msg += " #{@objects.length} objects" if @objects.any?
      msg += " #{@modules.length} objects" if @modules.any?
      msg
    end

    # Order is important:
    alias inspect_original inspect # Call this if you need to
    alias inspect to_string
    alias to_s to_string

    private

    # Collect methods from both objects and modules for delegation.
    # Ensures all public method names in @objects and @modules are unique; ancestors are not examined.
    # Although Ruby allows multiple inheritance via mixins, this class does not.
    # If more than one object or module responds to a method name,a NameError will be raised.
    # This is to avoid ambiguity and unintended consequences.
    # Note that respond_to? will return true for ambiguous methods.
    def define_delegators!
      # Passing a block to Hash.new tells Ruby what to do when you access a missing key.
      # The block takes two arguments:
      #   h - the hash itself
      #   k - the missing key
      # Inside the block: h[k] = []
      #   This creates a new empty array and assigns it as the value for that key.
      #   So the next time you access the key, the value is already set to an empty array.
      method_map = Hash.new { |h, k| h[k] = [] } # Initialization for collecting all public methods across objects

      # Store an entry for each public method from every object
      # Ignore public methods from ancestors of obj
      @objects.each do |obj|
        obj.public_methods(false).each { |m| method_map[m] << obj }
      end

      # Module/class methods (singleton methods)
      # Ignore public methods from ancestors of mod
      @modules.each do |mod|
        mod.methods(false).each { |m| method_map[m] << mod }
      end

      # Copy delegators into this instance and ensure only one method per name is defined
      #
      # define_singleton_method defines a method that only one object can use.
      # It attaches the method to that object’s singleton class (a.k.a its eigenclass).
      method_map.each do |method_name, responders|
        case responders.size
        when 0 # This should not be possible
          # Do nothing because respond_to? will return false and a NameError will be raised if invoked as usual
        when 1 # Happy path: exactly one responder
          target = responders.first
          define_singleton_method(method_name) do |*args, &block| # add this method as method_name to self
            target.public_send(method_name, *args, &block)
          end
        else # Error: more than one responder (ambiguous)
          signatures = responders.map(&:to_s).join(', ')
          error_message = "Ambiguous method '#{method_name}': multiple objects/modules (#{signatures}) respond"
          define_singleton_method(method_name) do |*| # add this method as method_name to self
            raise AmbiguousMethodError, error_message
          end
        end
      end
    end

    # Copy constants from modules and classes into this instance
    def define_module_constants!
      @modules.each do |mod|
        unless mod.is_a?(Module)
          puts "Error: #{mod} is not a Module or Class; ignoring constant.".red
          next
        end
        const_name = mod.name.split('::').last
        Object.const_set(const_name, mod) unless Object.const_defined?(const_name)
      end
    end
  end
end
