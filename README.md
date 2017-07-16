# Susanin

Extend `polymorphic_url` to replace simple resource with array of resources.

## Installation

Add this line to your application's Gemfile:

    gem 'susanin'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install susanin

## Usage

By default gems do nothing. Include module 'susanin' to the controller.

```ruby
class ApplicationController < ActionController::Base
  include ::Susanin

  susanin do
    [
      [:owner,              ->(r) { [:admin] }],
      [[:frontend, Link],   ->(r) { [:frontend, r] }],
      [User,                ->(r) { [:owner, r] }],
      [Project,             ->(r) { [:owner, r] }],
      [Link,                ->(r) { [:owner, r] }],
      [Admin,               ->(r) { [r.company, r] }],
      [Photo,               ->(r) { [r.admin.company, r.admin, r] }],
      [Gallery,             ->(r) { [r.company, r] }]
    ]
  end

end
```

Then you're able to call `link_to` method wihtout knowlege about the nested resources inside `routes.rb`. Instead of this:

```ruby
link_to user.email, [:edit, user.company, user], class: 'button'
```

You are able to write this:

```ruby
link_to user.email, [:edit, user], class: 'button'
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/susanin/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
