# RailsOr

[![Gem Version](https://img.shields.io/gem/v/rails_or.svg?style=flat)](https://rubygems.org/gems/rails_or)
[![Build Status](https://travis-ci.org/khiav223577/rails_or.svg?branch=master)](https://travis-ci.org/khiav223577/rails_or)
[![RubyGems](http://img.shields.io/gem/dt/rails_or.svg?style=flat)](https://rubygems.org/gems/rails_or)
[![Code Climate](https://codeclimate.com/github/khiav223577/rails_or/badges/gpa.svg)](https://codeclimate.com/github/khiav223577/rails_or)
[![Test Coverage](https://codeclimate.com/github/khiav223577/rails_or/badges/coverage.svg)](https://codeclimate.com/github/khiav223577/rails_or/coverage)

`rails_or` is a Ruby Gem for adding the `#or` method in Rails 3+,

allowing use of the OR operator to combine WHERE or HAVING clauses. 

Though this method is available in Rails 5+, 

`rails_or` make it easier to use by adding syntax sugar to `#or` method.





## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rails_or'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rails_or

## Usage

### Same as Rails 5's #or method
```rb
Person.where(name: 'Pearl').or(Person.where(age: 24))
# is the same as
Person.where("name = ? OR age = ?", 'Pearl', 24)
```

### Easier to use 
No need to repeat writing `Model.joins(XXX).where(...)`
```rb
# before
User.joins(:posts).where(id: 2)
                  .or(User.joins(:posts).where('posts.title = ?',"title"))
                  .or(User.joins(:posts).where('posts.created_at > ?', 1.day.ago))
# after
User.joins(:posts).where(id: 2)
                  .or('posts.title': "title")
                  .or('posts.created_at > ?', 1.day.ago)
```
Support passing `Hash` / `Array` / `String` as parameters
```rb
Person.where(name: 'Pearl').or(age: 24)
Person.where(name: 'Pearl').or(['age = ?', 24])
Person.where(name: 'Pearl').or('age = ?', 24)
Person.where(name: 'Pearl').or('age = 24')
```



## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/khiav223577/rails_or. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

