require 'rails_or/version'
require 'rails_or/where_binding_mixs'
require 'active_record'
require 'rails_or/patches/null_relation' if defined?(ActiveRecord::NullRelation)

class ActiveRecord::Relation
  IS_RAILS3_FLAG = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('4.0.0')
  IS_RAILS5_FLAG = Gem::Version.new(ActiveRecord::VERSION::STRING) >= Gem::Version.new('5.0.0')
  FROM_VALUE_METHOD = %i[from_value from_clause].find{|s| method_defined?(s) }
  ASSIGN_FROM_VALUE = :"#{FROM_VALUE_METHOD}="
  if method_defined?(:or)
    if not method_defined?(:rails5_or)
      alias rails5_or or
      def or(*other)
        return rails5_or(rails_or_parse_parameter(*other))
      end
    end
  else
    def or(*other)
      other        = rails_or_parse_parameter(*other)
      combining    = group_values.any? ? :having : :where
      left  = RailsOr::WhereBindingMixs.new(send("#{combining}_values"), bind_values)
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

  def or_not(*args) # Works in Rails 4+
    self.or(klass.where.not(*args))
  end

  def or_having(hash)
    self.or(rails_or_spwan_relation(:having, hash))
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
    when Hash   ; rails_or_spwan_relation(:where, other)
    when Array  ; rails_or_spwan_relation(:where, other)
    when String ; rails_or_spwan_relation(:where, other)
    else        ; other
    end
  end

  def rails_or_copy_values_to(relation) # For Rails 5
    relation.joins_values = joins_values
    relation.limit_value = limit_value
    relation.group_values = group_values
    relation.distinct_value = distinct_value
    relation.order_values = order_values
    relation.offset_value = offset_value
    relation.references_values = references_values
  end

  def rails_or_spwan_relation(method, condition)
    relation = klass.send(method, condition)
    relation.send(ASSIGN_FROM_VALUE, send(FROM_VALUE_METHOD))
    rails_or_copy_values_to(relation) if IS_RAILS5_FLAG
    return relation
  end

  def rails_or_get_current_scope
    return clone if IS_RAILS3_FLAG
    # ref: https://github.com/rails/rails/blob/17ef58db1776a795c9f9e31a1634db7bcdc3ecdf/activerecord/lib/active_record/scoping/named.rb#L26
    # return self.all # <- cannot use this because some gem changes this method's behavior
    return (current_scope || default_scoped).clone
  end
end

class ActiveRecord::Base
  def self.or(*args)
    where('').or(*args)
  end
end
