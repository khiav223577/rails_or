require "rails_or/version"
require 'rails'
require 'active_record'

class ActiveRecord::Relation
  def or(relation)
    relation = self.except(:where).where(relation) if relation.class == Hash
    left = self.where_clauses.join(' AND ')
    right = relation.where_clauses.join(' AND ')
    return self.except(:where).where("(#{left}) OR (#{right})")
  end
end
