require "rails_or/version"
require 'rails'
require 'active_record'

class ActiveRecord::Relation
  if method_defined?(:or)
    alias rails5_or or
    def or(other)
      return rails5_or(parse_or_parameter(other))
    end
  else
    def or(other)
      combining = group_values.any? ? :having : :where
      left_values = send("#{combining}_values")
      right_values = parse_or_parameter(other).send("#{combining}_values")
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
private
  def parse_or_parameter(other)
    case other
    when Hash   ; self.except(:where).where(other.to_a.map{|s| s[0] = "#{s[0]} = ?" ; next s}.flatten) #TODO why hash is not working?
    when Array  ; self.except(:where).where(other)
    when String ; self.except(:where).where(other)
    else        ; other
    end
  end
end
class ActiveRecord::Base
  def self.or(*args)
    self.where('').or(*args)
  end
end
