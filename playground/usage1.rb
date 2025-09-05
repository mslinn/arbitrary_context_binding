require_relative 'define_stuff'

module Usage1
  include DefineStuff

  template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
  puts DefineStuff.acb_all.render template # Displays 'User: alice, Project: cool app'
end
