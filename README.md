# RailsOr

[![Gem Version](https://img.shields.io/gem/v/rails_or.svg?style=flat)](https://rubygems.org/gems/rails_or)
[![Build Status](https://travis-ci.org/khiav223577/rails_or.svg?branch=master)](https://travis-ci.org/khiav223577/rails_or)
[![RubyGems](http://img.shields.io/gem/dt/rails_or.svg?style=flat)](https://rubygems.org/gems/rails_or)
[![Code Climate](https://codeclimate.com/github/khiav223577/rails_or/badges/gpa.svg)](https://codeclimate.com/github/khiav223577/rails_or)
[![Test Coverage](https://codeclimate.com/github/khiav223577/rails_or/badges/coverage.svg)](https://codeclimate.com/github/khiav223577/rails_or/coverage)

`rails_or` is a Ruby Gem for you to write cleaner `OR` query.

It will use built-in `or` method, which was added in Rails 5, when possible, so that you don't need to worry about that it will polulate `active_model`. Otherwise, it implements `or` method for Rails 3 and Rails 4.

## Supports
- Ruby 2.2 ~ 2.7
- Rails 3.2, 4.2, 5.0, 5.1, 5.2, 6.0

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

### Clearer Syntax

```rb
# Before
user = User.where(account: account).or(User.where(email: account)).take

# After
user = User.where(account: account).or(email: account).take
```

```rb
# Before
class Post < ActiveRecord::Base
  scope :not_expired, ->{ where(end_time: nil).or(Post.where('end_time > ?', Time.now)) }
end

# After
class Post < ActiveRecord::Base
  scope :not_expired, ->{ where(end_time: nil).or('end_time > ?', Time.now) }
end
```


No need to repeat writing `Model.joins(XXX).where(...)`
```rb
# Before
User.joins(:posts).where(id: 2)
                  .or(User.joins(:posts).where('posts.title = ?',"title"))
                  .or(User.joins(:posts).where('posts.created_at > ?', 1.day.ago))
# After
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

## Other convenient methods

### or_not
(Only supports in Rails 4+)
```rb
Company.where.not(logo_image1: nil)
       .or_not(logo_image2: nil)
       .or_not(logo_image3: nil)
       .or_not(logo_image4: nil)
```

### or_having

```rb
Order.group('user_id')
     .having('SUM(price) > 1000')
     .or_having('COUNT(*) > 10')
```

## Examples

Let `A = { id: 1 }`, `B = { account: 'tester' }`, and `C = { email: 'test@example.com' }`

### A && (B || C)
```rb
u = User.where(A)
u.where(B).or(u.where(C))
# =>
# SELECT `users`.* FROM `users`
# WHERE `users`.`id` = 1 AND (`users`.`account` = 'tester' OR `users`.`email` = 'test@example.com')
```
### (B || C) && A
```rb
User.where(B).or(C).where(A)
# =>
# SELECT `users`.* FROM `users`
# WHERE (`users`.`account` = 'tester' OR `users`.`email` = 'test@example.com') AND `users`.`id` = 1
```
### A && B || A && C
```rb
User.where(A).where(B).or(User.where(A).where(C))
# =>
# SELECT `users`.* FROM `users`
# WHERE (`users`.`id` = 1 AND `users`.`account` = 'tester' OR `users`.`id` = 1 AND `users`.`email` = 'test@example.com')
```
### A && B || C
```rb
User.where(A).where(B).or(C)
# =>
# SELECT `users`.* FROM `users`
# WHERE (`users`.`id` = 1 AND `users`.`account` = 'tester' OR `users`.`email` = 'test@example.com')
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/khiav223577/rails_or. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

