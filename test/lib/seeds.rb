ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, force: true do |t|
    t.string :name
    t.string :email
    t.text :serialized_attribute
  end

  create_table :posts, force: true do |t|
    t.integer :user_id
    t.string :title
    t.datetime :start_time
  end

  create_table :user_messages, force: true do |t|
    t.integer :sender_user_id
    t.integer :receiver_user_id
    t.string :content
  end
end

require 'rails_compatibility/setup_autoload_paths'
RailsCompatibility.setup_autoload_paths [File.expand_path('../models/', __FILE__)]

ActiveRecord::Base.use_yaml_unsafe_load = true if ActiveRecord::Base.method_defined?(:use_yaml_unsafe_load) # For Rails 5.2
ActiveRecord.use_yaml_unsafe_load = true if ActiveRecord.respond_to?(:use_yaml_unsafe_load) # For Rails 7.0

users = User.create([
  { name: 'John', email: 'john@example.com' },
  { name: 'Pearl', email: 'pearl@example.com', serialized_attribute: { testing: true, deep: { deep: :deep }}},
  { name: 'Doggy', email: 'kathenrie@example.com' },
])

Post.create([
  { title: "John's post1", user_id: users[0].id, start_time: Time.parse('2016/1/1') },
  { title: "John's post2", user_id: users[0].id, start_time: Time.parse('2016/2/1') },
  { title: "John's post3", user_id: users[0].id },
  { title: "Pearl's post1", user_id: users[1].id },
  { title: "Pearl's post2", user_id: users[1].id },
  { title: "Doggy's post1", user_id: users[2].id, start_time: Time.parse('2016/10/15') },
])

UserMessage.create([
  { sender_user_id: users[0].id, receiver_user_id: users[1].id, content: 'user1 send to user2' },
  { sender_user_id: users[0].id, receiver_user_id: users[2].id, content: 'user1 send to user3' },
  { sender_user_id: users[1].id, receiver_user_id: users[2].id, content: 'user2 send to user3' },
  { sender_user_id: users[2].id, receiver_user_id: users[0].id, content: 'user3 send to user1' },
])
