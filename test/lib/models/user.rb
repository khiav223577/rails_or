# frozen_string_literal: true

class User < ActiveRecord::Base
  if Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('7.1.0')
    serialize :serialized_attribute, Hash
  else
    serialize :serialized_attribute, type: Hash
  end

  has_many :posts
  has_many :sent_messages,     class_name: 'UserMessage', foreign_key: :sender_user_id,   dependent: :destroy
  has_many :received_messages, class_name: 'UserMessage', foreign_key: :receiver_user_id, dependent: :destroy

  scope :none, ->{ where('0') } if not User.respond_to?(:none) # For Rails 3
  if RailsOr::IS_RAILS3_FLAG
    class << self
      alias origin_from from if not method_defined?(:origin_from)
      def from(string)
        return origin_from if string.is_a?(String)
        return origin_from("(#{string.to_sql}) subquery") # Rails 3's #from only support string arguments
      end
    end
  end
end
