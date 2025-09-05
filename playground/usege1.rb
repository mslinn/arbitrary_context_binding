require 'arbitrary_context_binding'
require_relative 'define_stuff'

acb_all = ArbitraryContextBinding.new(
  objects: [],
  modules: [Blah, TestHelpers]
)

template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
puts acb_all.render template # Displays 'User: alice, Project: cool app'
