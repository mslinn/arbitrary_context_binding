require_relative 'define_stuff'

module Usage1
  include Ex1

  template = 'User: <%= @repository.user_name %>, Project: <%= @project.title %>'
  puts Ex1.acb_all.render template # Displays 'User: alice, Project: cool app'
end
