require "rails_or/version"
require 'rails'
require 'active_record'

class ActiveRecord::Relation
  def or(other)
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
    #relation = self.except(:where).where(relation) if relation.class == Hash
    #left = self.where_clauses.join(' AND ')
    #right = other.where_clauses.join(' AND ')
    #return self.except(:where).where("(#{left}) OR (#{right})")
  end
end
