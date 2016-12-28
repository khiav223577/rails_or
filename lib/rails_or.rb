require "rails_or/version"
require 'rails'
require 'active_record'

class ActiveRecord::Relation
  if method_defined?(:or)
    alias rails5_or or
    def or(other)
      other = self.except(:where).where(other) if other.class == Hash
      return rails5_or(other)
    end
  else
    def or(other)
      other = self.except(:where).where(other) if other.class == Hash
      combining = group_values.any? ? :having : :where
      left_values = send("#{combining}_values")
      right_values = other.send("#{combining}_values")
      common = left_values & right_values
      mine = left_values - common
      theirs = right_values - common
      if mine.any? && theirs.any?
        mine = mine.map { |x| String === x ? Arel.sql(x) : x }
        theirs = theirs.map { |x| String === x ? Arel.sql(x) : x }
        mine = [Arel::Nodes::And.new(mine)] if mine.size > 1
        theirs = [Arel::Nodes::And.new(theirs)] if theirs.size > 1
        common << Arel::Nodes::Or.new(mine.first, theirs.first)
      end
      send("#{combining}_values=", common)
      return self  
    end
  end
end
class ActiveRecord::Base
  def self.or(*args)
    self.where('').or(*args)
  end
end
