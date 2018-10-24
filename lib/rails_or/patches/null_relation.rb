module ActiveRecord::NullRelation
  if method_defined?(:or) and not method_defined?(:rails5_or)
    alias rails5_or or
    def or(*other)
      rails5_or(RailsOr.parse_parameter(self, *other))
    end
  end
end
