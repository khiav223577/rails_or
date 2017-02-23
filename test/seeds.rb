ActiveRecord::Schema.define do
  self.verbose = false

  create_table :users, :force => true do |t|
    t.string :name
    t.string :email
    t.text :serialized_attribute
  end
  create_table :posts, :force => true do |t|
    t.integer :user_id
    t.string :title
    t.datetime :start_time
  end
  create_table :user_messages, :force => true do |t|
    t.integer :sender_user_id
    t.integer :receiver_user_id
    t.string :content
  end
end
class User < ActiveRecord::Base
  serialize :serialized_attribute, Hash
  has_many :posts
  has_many :sent_messages,     :class_name => "UserMessage", :foreign_key => :sender_user_id,   :dependent => :destroy
  has_many :received_messages, :class_name => "UserMessage", :foreign_key => :receiver_user_id, :dependent => :destroy
end
class Post < ActiveRecord::Base
  belongs_to :user
  scope :with_title_like, proc{|s| where('title LIKE ?', s) }
end
class UserMessage < ActiveRecord::Base
  
end
users = User.create([
  {:name => 'John', :email => 'john@example.com'},
  {:name => 'Pearl', :email => 'pearl@example.com', :serialized_attribute => {:testing => true, :deep => {:deep => :deep}}},
  {:name => 'Kathenrie', :email => 'kathenrie@example.com'},
])
Post.create([
  {:title => "John's post1", :user_id => users[0].id, :start_time => Time.parse('2016/1/1')},
  {:title => "John's post2", :user_id => users[0].id, :start_time => Time.parse('2016/2/1')},
  {:title => "John's post3", :user_id => users[0].id},
  {:title => "Pearl's post1", :user_id => users[1].id},
  {:title => "Pearl's post2", :user_id => users[1].id},
  {:title => "Kathenrie's post1", :user_id => users[2].id},
])
UserMessage.create([
  {:sender_user_id => users[0].id, :receiver_user_id => users[1].id, :content => 'user1 send to user2'},
  {:sender_user_id => users[0].id, :receiver_user_id => users[2].id, :content => 'user1 send to user3'},
  {:sender_user_id => users[1].id, :receiver_user_id => users[2].id, :content => 'user2 send to user3'},
  {:sender_user_id => users[2].id, :receiver_user_id => users[0].id, :content => 'user3 send to user1'},
])
