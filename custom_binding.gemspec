require_relative 'lib/custom_binding/version'

Gem::Specification.new do |spec|
  host = 'https://github.com/mslinn/custom_binding'

  spec.authors               = ['Mike Slinn']
  spec.description           = <<~END_DESC
    Construct or modify a Ruby binding and make it available anywhere.
    Useful for ERB rendering.
  END_DESC
  spec.email                 = ['mslinn@mslinn.com']
  spec.files                 = Dir['.rubocop.yml', 'LICENSE.*', 'Rakefile', '{lib,spec,playground}/**/*', '*.gemspec', '*.md']
  spec.homepage              = host
  spec.license               = 'MIT'
  spec.metadata = {
    'allowed_push_host' => 'https://rubygems.org',
    'bug_tracker_uri'   => "#{host}/issues",
    'changelog_uri'     => "#{host}/CHANGELOG.md",
    'homepage_uri'      => spec.homepage,
    'source_code_uri'   => host,
  }
  spec.name                 = 'custom_binding'
  spec.platform             = Gem::Platform::RUBY
  spec.post_install_message = <<~END_MESSAGE

    Thanks for installing #{spec.name}!

  END_MESSAGE
  spec.require_paths         = ['lib']
  spec.required_ruby_version = '>= 3.1.0'
  spec.summary               = 'Construct or modify a Ruby binding and make it available anywhere'
  spec.version               = CustomBinding::VERSION
end
