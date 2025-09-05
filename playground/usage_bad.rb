require_relative 'define_stuff'

# This is an example of defining a top-level object:
acb_all = ArbitraryContextBinding.new(
  objects: [],
  modules: [Blah, TestHelpers]
)

# Do not define top-level objects in Ruby unless you have a license ;)
# Look at usage_good.rb for a positive example

template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
puts acb_all.render template # Displays 'User: alice, Project: cool app'
