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
      
      mine_where, mine_binds = rails_or_extract_where_values(left_values, self.bind_values){|node| !common.include?(node) }
      theirs_where, theirs_binds = rails_or_extract_where_values(right_values, other.bind_values){|node| !common.include?(node) }
      _, common_binds = rails_or_extract_where_values(right_values, other.bind_values){|node| common.include?(node) }

      if mine_where.any? && theirs_where.any?
        common << Arel::Nodes::Or.new(rails_or_values_to_arel(mine_where), rails_or_values_to_arel(theirs_where))
      end

      relation = rails_or_get_current_scope
      relation.send("#{combining}_values=", common)
      relation.bind_values = common_binds + mine_binds + theirs_binds
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
  def rails_or_extract_where_values(where_values, bind_values) 
    binds_index = 0
    new_bind_values = []
    new_where_values = where_values.select do |node|
      flag = yield(node)
      if not node.is_a?(String)
        binds_contains = node.grep(Arel::Nodes::BindParam).size
        pre_binds_index = binds_index
        binds_index += binds_contains
        (pre_binds_index...binds_index).each{|i| new_bind_values << bind_values[i] } if flag
      end
      next flag
    end
    return [new_where_values, new_bind_values]
  end
  def rails_or_values_to_arel(values)
    values.map!{|x| rails_or_wrap_arel(x) }
    return (values.size > 1 ? Arel::Nodes::And.new(values) : values)
  end
  def rails_or_wrap_arel(node)
    return node if Arel::Nodes::Equality === node
    return Arel::Nodes::Grouping.new(String === node ? Arel.sql(node) : node)
  end
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
