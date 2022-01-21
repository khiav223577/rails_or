# frozen_string_literal: true

class Post < ActiveRecord::Base
  belongs_to :user
  scope :with_title_like, proc{|s| where('title LIKE ?', s) }
end
