module ActiveRecord::NullRelation
  if method_defined?(:or) and not method_defined?(:rails5_or)
    alias rails5_or or
    def or(*other)
      rails5_or(rails_or_parse_parameter(*other))
    end
  end
end
