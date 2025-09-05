require_relative 'define_stuff'

module GoodExample
  template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
  puts DefineStuff.acb_all.render template # Displays 'User: alice, Project: cool app'
end
