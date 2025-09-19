# `custom_binding` [![Gem Version](https://badge.fury.io/rb/custom_binding.svg)](https://badge.fury.io/rb/custom_binding)

Construct or modify a Ruby binding and make it available anywhere.
This is useful for [ERB rendering](https://github.com/ruby/erb).

Also monkey-patches [Binding](https://ruby-doc.org/3.4.1/Binding.html) so its output is useful for debugging.

This Ruby gem was created because [Nugem 2](https://github.com/mslinn/nugem/tree/wip) needed it,
and this seemed like such a generally useful gem to have around, especially if you use ERBs.

You can [read an article](https://www.mslinn.com/ruby/6900-custom_binding.html)
I wrote that:

- Introduces what Ruby bindings are.
- Provides simple examples of how manipulating Ruby bindings can be useful.
- Discusses this `custom_binding` gem in detail.


## Installation

Either add this line to your application&rsquo;s `Gemfile`:

```ruby
gem 'custom_binding'
```

... or add the following to your application&rsquo;s `.gemspec`:

```ruby
spec.add_dependency 'custom_binding'
```

And then execute:

```shell
$ bundle
```


## Usage

See [`playground/examples.rb`](playground/examples.rb).


## Development

After checking out this git repository, install dependencies by typing:

```shell
$ bin/setup
```

You should do the above before running Visual Studio Code.


### Run the Tests

```shell
$ bin/rspec
```


### Interactive Session

The following will allow you to experiment:

```shell
$ bin/console
```

Here is a short example of how the `Binding` monkey patch overrides `Binding#to_s`
and `Binding#inspect` to make life easier for programmers:

```shell
$ bin/console
irb(main):001> y = 3
=> 3
irb(main):002> $blah = 33
=> 33
irb(main):003> b = binding
=> #&lt;Binding 10020 { globals: [:$blah], locals: [:b, :y] }>
```


### Local Installation

To install this gem onto your local machine, type:

```shell
$ bundle exec rake install
```


### To Release A New Version

To create a git tag for the new version, push git commits and tags,
and push the new version of the gem to the Gem server, type:

```shell
$ bundle exec rake release
```


## Contributing

Bug reports and pull requests are welcome at https://github.com/mslinn/custom_binding.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
