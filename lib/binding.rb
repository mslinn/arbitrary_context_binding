# Run this code at startup
BEGIN {
   ignored = %i[$DEBUG_RDOC $globals_saved] # Do not admit to the user that these globals exist
   $globals_saved = TOPLEVEL_BINDING.send(:global_variables) + ignored
}

# Binding is an opaque data type, which makes debugging painful
# This monkey patch shows the contents in a programmer-friendly way
class Binding
  IGNORED_METHODS = %i[inspect to_s].freeze

  # @return [String] all definitions in @binding
  def to_s
    contents = map do |key, value|
      "#{key}: #{value.map(&:to_s).join(', ')}"
    end.join("\n  ")
    "#<Binding #{object_id}\n  #{contents}\n>"
  end

  # @return [String] compact representation of all definitions in @binding
  def inspect
    contents = binding_contents.map do |key, value|
      "#{key}: #{value}"
    end.join(', ')
    "#<Binding #{object_id} { #{contents} }>"
  end

  private

  # Report all variables (local, instance, class, global) and method names defined in the binding
  # that are not part of TOPLEVEL_BINDING.
  # Only methods defined in the receiver are reported; inherited methods are ignored.
  # @return [Hash] a hash with keys :class_vars, :instance_vars, :globals, :locals, :methods.
  def binding_contents
    class_vars = receiver.class.class_variables

    globals_filtered = global_variables.reject { |x| $globals_saved.include?(x) }.sort

    instance_vars = receiver.instance_variables.sort

    # Automatically constructed Ruby variable _ provides a way to access the last return value; ignore it
    locals = local_variables.reject { |x| x == :_ }.sort

    methods_filtered = receiver.methods(false).reject { |x| IGNORED_METHODS.include?(x) }.sort

    result = {}
    result[:class_vars]    = class_vars if class_vars.any?
    result[:globals]       = globals_filtered if globals_filtered.any?
    result[:instance_vars] = instance_vars if instance_vars.any?
    result[:locals]        = locals if locals.any?
    result[:methods]       = methods_filtered if methods_filtered.any?
    result
  end
end
