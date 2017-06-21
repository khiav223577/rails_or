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
      left  = RailsOrWhereBindingMix.new(self.send("#{combining}_values"), self.bind_values)
      right = RailsOrWhereBindingMix.new(other.send("#{combining}_values"), other.bind_values)
      common_where_values = left.where_values & right.where_values
      
      common = RailsOrWhereBindingMix.new(common_where_values, right.select{|node| common_where_values.include?(node) }.bind_values)
      left  = left.select{|node| !common_where_values.include?(node) }
      right = right.select{|node| !common_where_values.include?(node) }
      
      if left.where_values.any? && right.where_values.any?
        arel_or = Arel::Nodes::Or.new(
          rails_or_values_to_arel(left.where_values),
          rails_or_values_to_arel(right.where_values),
        )
        common.merge!(RailsOrWhereBindingMix.new([arel_or], left.bind_values + right.bind_values))
      end

      relation = rails_or_get_current_scope
      relation.send("#{combining}_values=", common.where_values)
      relation.bind_values = common.bind_values
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
  class RailsOrWhereBindingMix
    attr_reader :where_values
    attr_reader :bind_values
    def initialize(where_values, bind_values)
      @where_values = where_values
      @bind_values = bind_values
    end
    def merge!(other)
      @where_values += other.where_values
      @bind_values += other.bind_values
      return self
    end
    def select
      binds_index = 0
      new_bind_values = []
      new_where_values = @where_values.select do |node|
        flag = yield(node)
        if not node.is_a?(String)
          binds_contains = node.grep(Arel::Nodes::BindParam).size
          pre_binds_index = binds_index
          binds_index += binds_contains
          (pre_binds_index...binds_index).each{|i| new_bind_values << @bind_values[i] } if flag
        end
        next flag
      end
      return RailsOrWhereBindingMix.new(new_where_values, new_bind_values)
    end
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
