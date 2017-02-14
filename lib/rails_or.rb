require "rails_or/version"
require 'active_record'

class ActiveRecord::Relation
  IS_RAILS3_FLAG = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.0.0')
  if method_defined?(:or)
    alias rails5_or or
    def or(*other)
      return rails5_or(rails_or_parse_parameter(*other))
    end
  else
    def or(*other)
      other        = rails_or_parse_parameter(*other)
      combining    = group_values.any? ? :having : :where
      left_values  = send("#{combining}_values")
      right_values = other.send("#{combining}_values")
      common       = left_values & right_values
      mine         = left_values - common
      theirs       = right_values - common
      if mine.any? && theirs.any?
        mine.map!{|x| String === x ? Arel.sql(x) : x }
        theirs.map!{ |x| String === x ? Arel.sql(x) : x }
        mine = [Arel::Nodes::And.new(mine)] if mine.size > 1
        theirs = [Arel::Nodes::And.new(theirs)] if theirs.size > 1
        common << Arel::Nodes::Or.new(mine.first, theirs.first)
      end
      relation = rails_or_get_current_scope
      relation.send("#{combining}_values=", common)
      relation.bind_values = self.bind_values + other.bind_values
      return relation  
    end
  end
  def or_not(*args)
    raise 'This method is not support in Rails 3' if IS_RAILS3_FLAG
    return self.or(klass.where.not(*args))
  end
  def or_having(*args)
    self.or(klass.having(*args))
  end
private
  def rails_or_parse_parameter(*other)
    other = other.first if other.size == 1
    case other
    when Hash   ; klass.where(other)
    when Array  ; klass.where(other)
    when String ; klass.where(other)
    else        ; other
    end
  end
  def rails_or_get_current_scope
    return self.clone if IS_RAILS3_FLAG
    #ref: https://github.com/rails/rails/blob/17ef58db1776a795c9f9e31a1634db7bcdc3ecdf/activerecord/lib/active_record/scoping/named.rb#L26
    #return self.all # <- cannot use this because some gem changes this method's behavior
    return (self.current_scope || self.default_scoped).clone
  end
end
class ActiveRecord::Base
  def self.or(*args)
    self.where('').or(*args)
  end
end
