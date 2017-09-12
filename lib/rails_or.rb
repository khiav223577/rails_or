require "rails_or/version"
require "rails_or/where_binding_mixs"
require 'active_record'

class ActiveRecord::Relation
  IS_RAILS3_FLAG = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.0.0')
  if method_defined?(:or)
    if not method_defined?(:rails5_or)
      alias_method :rails5_or, :or
      def or(*other)
        return rails5_or(rails_or_parse_parameter(*other))
      end
    end
  else
    def or(*other)
      other        = rails_or_parse_parameter(*other)
      combining    = group_values.any? ? :having : :where
      left  = RailsOr::WhereBindingMixs.new(self.send("#{combining}_values"), self.bind_values)
      right = RailsOr::WhereBindingMixs.new(other.send("#{combining}_values"), other.bind_values)
      common = left & right

      left  -= common
      right -= common
      
      if left.where_values.any? && right.where_values.any?
        arel_or = Arel::Nodes::Or.new(
          rails_or_values_to_arel(left.where_values),
          rails_or_values_to_arel(right.where_values),
        )
        common += RailsOr::WhereBindingMixs.new([arel_or], left.bind_values + right.bind_values)
      end

      relation = rails_or_get_current_scope
      if defined?(ActiveRecord::NullRelation) # Rails 3 does not have ActiveRecord::NullRelation
        return other if relation.is_a?(ActiveRecord::NullRelation)
        return relation if other.is_a?(ActiveRecord::NullRelation)
      end
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
    when Hash   ; rails_or_spwan_relation(other)
    when Array  ; rails_or_spwan_relation(other)
    when String ; rails_or_spwan_relation(other)
    else        ; other
    end
  end

  def rails_or_spwan_relation(condition) # for rails 5
    relation = klass.where(condition)
    relation.joins_values = self.joins_values
    relation.limit_value = self.limit_value
    relation.group_values = self.group_values
    relation.distinct_value = self.distinct_value
    return relation
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
