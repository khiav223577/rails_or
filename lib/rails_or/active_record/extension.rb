class ActiveRecord::Relation
  if method_defined?(:or)
    if not method_defined?(:rails5_or)
      alias rails5_or or
      def or(*other)
        rails5_or(RailsOr.parse_parameter(self, *other))
      end
    end
  else
    def or(*other)
      other        = RailsOr.parse_parameter(self, *other)
      combining    = group_values.any? ? :having : :where
      left  = RailsOr::WhereBindingMixs.new(send("#{combining}_values"), bind_values)
      right = RailsOr::WhereBindingMixs.new(other.send("#{combining}_values"), other.bind_values)
      common = left & right

      left  -= common
      right -= common

      if left.where_values.any? && right.where_values.any?
        arel_or = Arel::Nodes::Or.new(
          RailsOr.values_to_arel(left.where_values),
          RailsOr.values_to_arel(right.where_values),
        )
        common += RailsOr::WhereBindingMixs.new([arel_or], left.bind_values + right.bind_values)
      end

      relation = RailsOr.get_current_scope(self)
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
    self.or(RailsOr.spwan_relation(self, :having, hash))
  end
end

class ActiveRecord::Base
  def self.or(*args)
    where('').or(*args)
  end
end
