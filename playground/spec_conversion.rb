puts '=== Using pre-existing instance variables ==='
template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
result = acb_all.render(template)
puts result == 'User: alice, Project: cool app'

puts '=== Delegation from modules ==='
template = 'v=<%= version %>, h=<%= helper %>'
puts acb_module.render(template) == 'v=9.9.9, h=helper called'

template = "<%= greet('bob') %>"
puts acb_module.render(template) == 'Hello, bob!'

template = '<%= with_block { |x| x.upcase } %>'
puts acb_module.render(template) == 'BLOCK ARG'

template = '<%= helper %>'
begin
  acb_modules.render(template)
rescue AmbiguousMethodError => e
  puts e.message.include?("Ambiguous method 'helper'")
end

puts '=== Delegation from objects ==='
template = 'User: <%= user_name %>, Title: <%= title %>'
puts acb_objects.render(template) == 'User: alice, Title: cool app'

puts '=== When only one object responds ==='
puts acb12.render('<%= foo %>') == 'foo from obj1'
puts acb12.render('<%= bar %>') == 'bar from obj2'

puts '=== When no object responds ==='
begin
  acb.render('<%= baz %>')
rescue NameError
  puts true
end

begin
  acb12.render('<%= baz %>')
rescue NameError
  puts true
end

puts '=== When multiple objects and/or modules respond ==='
begin
  acb13.render('<%= foo %>')
rescue AmbiguousMethodError => e
  puts e.message.include?("Ambiguous method 'foo'")
end

begin
  obj = Struct.new(:helper).new('object helper')
  template = '<%= helper %>'
  acb_dup_method.render(template)
rescue AmbiguousMethodError => e
  puts e.message.include?("Ambiguous method 'helper'")
end

puts '=== With respond_to? ==='
puts acb12.respond_to?(:foo) == true
puts acb12.respond_to?(:bar) == true
puts acb12.respond_to?(:baz) == false

puts acb13.respond_to?(:foo) == true
begin
  acb13.foo
rescue AmbiguousMethodError => e
  puts e.message.include?("Ambiguous method 'foo'")
end
