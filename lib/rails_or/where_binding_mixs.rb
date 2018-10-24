class RailsOr::WhereBindingMixs
  attr_reader :where_values
  attr_reader :bind_values

  def initialize(where_values, bind_values)
    @where_values = where_values
    @bind_values = bind_values
  end

  def +(other)
    self.class.new(@where_values + other.where_values, @bind_values + other.bind_values)
  end

  def -(other)
    select{|node| !other.where_values.include?(node) }
  end

  def &(other)
    common_where_values = @where_values & other.where_values
    return select{|node| common_where_values.include?(node) }
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
    return self.class.new(new_where_values, new_bind_values)
  end
end
