require 'test_helper'

class RailsOrTest < Minitest::Test
  def setup
    
  end

  def test_that_it_has_a_version_number
    refute_nil ::RailsOr::VERSION
  end
#--------------------------------
#  Parameter check
#--------------------------------
  def test_or_with_model1
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 2')).to_a
  end

  def test_or_with_model2
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where(:id => 1).or(Post.where(:id => 2)).to_a
  end

  def test_or_with_string_argument
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or('id = 2').to_a
  end

  def test_or_with_hash_argument
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(:id => 2).to_a
  end

  def test_or_with_array_argument
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(['id = ?', 2]).to_a
  end

  def test_or_with_multiple_arguments1
    expected = Post.where('id = ? or id = ?', 1, 2).to_a
    assert_equal expected, Post.where('id = 1').or('id = ?', 2).to_a
  end

  def test_or_with_multiple_arguments2
    expected = Post.where('id = ? or id = ? or id = ?', 1, 2, 3).to_a
    assert_equal expected, Post.where('id = 1').or('id = ? OR id = ?', 2, 3).to_a
    assert_equal expected, Post.where('id = 1').or('id = ?', 2).or('id = ?', 3).to_a
  end
#--------------------------------
#  Common condition
#--------------------------------
  def test_or_with_shared_where 
    expected = Post.where('id = 1 and (title = ? or title = ?)', "John's post1", "John's post2").to_a
    target = Post.where('id = 1').where(:title => "John's post1").or(Post.where('id = 1').where(:title => "John's post2"))
    assert_equal expected, target.to_a

    # Rails 5's native #or implementation doesn't merge same condition
    expected = (Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new('5.0.0') ? 1 : 2)
    assert_equal expected, target.to_sql.scan('id = 1').size
  end

  def test_or_with_shared_where_and_binding_values
    p1 = Post.where(id: 1)
    expected = p1.where('title = ? or title = ?', "John's post1", "John's post2").to_a
    target = p1.where(:title => "John's post1").or(p1.where(:title => "John's post2"))
    assert_equal expected, target.to_a
  end

  def test_or_with_unneeded_brackets
    #Wrong: SELECT "users".* FROM "users"  WHERE (("users"."id" = 1) OR ("users"."id" = 2))
    #Correct: SELECT "users".* FROM "users"  WHERE ("users"."id" = 1 OR "users"."id" = 2)
    assert_equal 1, User.where(:id => 1).or(:id => 2).to_sql.count('(')
  end
#--------------------------------
#  Multiple columns
#--------------------------------
  def test_or_with_multiple_attributes
    expected = Post.where('id = 1 or title = ?', "Kathenrie's post1").to_a
    assert_equal expected, Post.where('id = 1').or(:title => "Kathenrie's post1").to_a
  end
#--------------------------------
#  join
#--------------------------------
  def test_or_with_join #Rails 5 doesn't support this
    expected = User.joins(:posts).where('user_id = 1 AND (title = ? OR title = ? OR title = ?)', "John's post1", "John's post2", "John's post3").to_a
    assert_equal expected, User.joins(:posts).where('0')
                               .or(:id => 1, :'posts.title' => "John's post1")
                               .or(:id => 1, :'posts.title' => "John's post2")
                               .or(:id => 1, :'posts.title' => "John's post3").to_a
  end

  def test_or_with_join_and_no_join #Rails 5 doesn't support this
    expected = User.joins(:posts).where('user_id = 1 AND title = ? OR user_id = 2', "John's post2").to_a
    assert_equal expected, User.joins(:posts).where(:id => 1, :'posts.title' => "John's post2").or(:id => 2).to_a
  end
#--------------------------------
#  having
#--------------------------------
  def test_or_with_having #Rails 5 doesn't support this
    expected = Post.group(:user_id).having("COUNT(*) = 1 OR COUNT(*) = 2").to_a
    assert_equal expected, Post.group(:user_id).having("COUNT(*) = 1").or(Post.having("COUNT(*) = 2")).to_a
    assert_equal expected, Post.group(:user_id).having("COUNT(*) = 1").or_having("COUNT(*) = 2").to_a
  end

  def test_or_with_join_and_having #Rails 5 doesn't support this
    expected = User.joins(:posts).group(:user_id).having("COUNT(*) = 1 OR COUNT(*) > 1").to_a
    assert_equal expected, User.joins(:posts).group(:user_id).having("COUNT(*) > 1").or_having("COUNT(*) = 1").to_a
  end
#--------------------------------
#  uniq / limit / offset / order
#--------------------------------
  def test_or_with_limit #Rails 5 doesn't support this
    expected = Post.where('user_id = 1 OR user_id = 2').limit(4).to_a
    assert_equal expected, Post.limit(4).where(:user_id => 1).or(:user_id => 2).to_a
  end

  def test_or_with_uniq #Rails 5 doesn't support this
    expected = Post.distinct.where('user_id = 1 OR user_id = 2').pluck(:user_id)
    assert_equal expected, Post.distinct.where(:user_id => 1).or(:user_id => 2).pluck(:user_id)
  end

  def test_or_with_offset #Rails 5 doesn't support this
    expected = Post.where('user_id = 1 OR user_id = 2').offset(3).first
    assert_equal expected, Post.offset(3).where(:user_id => 1).or(:user_id => 2).first
  end

  def test_or_with_order
    expected = Post.where('user_id = 1 OR user_id = 2 OR user_id = 3').order('user_id desc').pluck(:user_id)
    assert_equal expected, Post.order('user_id desc').where(:user_id => 1).or(:user_id => 2).or(:user_id => 3).pluck(:user_id)
  end
#--------------------------------
#  logic order
#--------------------------------
  def test_A_and_B_or_C # (A && B) || C, C || (B && A)
    expected = Post.where('(user_id = ? AND title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
    assert_equal expected, Post.where(:user_id => 1).where(:title => "John's post1").or(:user_id => 2).to_a
    assert_equal expected, Post.where(:user_id => 2).or(Post.where(:title => "John's post1").where(:user_id => 1)).to_a
  end

  def test_A_or_B_and_C # (A || B) && C
    expected = Post.where('(user_id = ? OR user_id = ?) AND title LIKE ?', 1, 2, "John's %").to_a
    assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where('title LIKE ?', "John's %").to_a
  end

  if Gem::Version.new(ActiveRecord::VERSION::STRING) > Gem::Version.new('4.0.2')
    def test_A_and_not_B_or_C # (A && !B) || C, C || (!B && A)
      expected = Post.where('(user_id = ? AND NOT title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
      assert_equal expected, Post.where(:user_id => 1).where.not(:title => "John's post1").or(:user_id => 2).to_a
      assert_equal expected, Post.where(:user_id => 2).or(Post.where.not(:title => "John's post1").where(:user_id => 1)).to_a
    end
    def test_A_or_B_and_not_C # (A || B) && !C
      expected = Post.where('(user_id = ? OR user_id = ?) AND title NOT LIKE ?', 1, 2, "John's %").to_a
      assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where.not('title LIKE ?', "John's %").to_a
    end
    def test_A_and_not_B_or_not_C # (A && !B) || !C, !C || (!B && A)
      expected = Post.where('(title LIKE ? AND user_id != ?) OR title NOT LIKE ?', 1, "Kathenrie's %", "Pearl's %").to_a
      assert_equal expected, Post.where('title LIKE ?', "Kathenrie's %").where.not(:user_id => 1).or_not('title LIKE ?', "Pearl's %").to_a
      assert_equal expected, Post.where.not('title LIKE ?', "Pearl's %").or(Post.where.not(:user_id => 1).where('title LIKE ?', "Kathenrie's %")).to_a
    end
  end
#--------------------------------
#  Nested
#--------------------------------
  def test_nested_or # (A && (B || C)) || D, ((B || C) && A) || D
    expected = Post.where('(title like ?) AND (start_time IS NULL OR start_time > ?) OR (title = ?)', 'John%', Time.parse('2016/1/15'), "Pearl's post1").pluck(:title)
    p1 = Post.with_title_like('John%').where('start_time IS NULL OR start_time > ?', Time.parse('2016/1/15'))
    assert_equal expected, p1.or(:title => "Pearl's post1").pluck(:title)

    p1 = Post.where(:start_time => nil).or('start_time > ?', Time.parse('2016/1/15')).with_title_like('John%')
    assert_equal expected, p1.or(:title => "Pearl's post1").pluck(:title)
  end
#--------------------------------
#  Association test
#--------------------------------
  def test_two_has_many_result # model.others1 || model.others2
    user = User.where(:name => 'John').first
    assert_equal user.sent_messages.or(user.received_messages).pluck(:content), [
      "user1 send to user2", 
      "user1 send to user3", 
      "user3 send to user1",
    ]
  end
#--------------------------------
#  Scope test
#--------------------------------
  def test_two_scope
    u1 = User.where(:name => 'John').first
    u2 = User.where(:name => 'Pearl').first
    assert_equal u1.posts.or(u2.posts).pluck(:title), [
      "John's post1", 
      "John's post2", 
      "John's post3", 
      "Pearl's post1",
      "Pearl's post2",
    ]
    assert_equal u1.posts.with_title_like('%post1').or(u2.posts.with_title_like('%post2')).pluck(:title), [
      "John's post1", 
      "Pearl's post2",
    ]
    assert_equal u1.posts.or(u2.posts.with_title_like('%post1')).pluck(:title), [
      "John's post1", 
      "John's post2", 
      "John's post3", 
      "Pearl's post1",
    ]
    assert_equal u1.posts.with_title_like('%post1').or(u2.posts).pluck(:title), [
      "John's post1", 
      "Pearl's post1",
      "Pearl's post2",
    ]
  end
#--------------------------------
#  From Rails 5
#--------------------------------
  def test_or_with_relation
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 2')).to_a
  end

  def test_or_identity
    expected = Post.where('id = 1').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 1')).to_a
    assert_equal expected, Post.where(:id => 1).or(Post.where('id = 1')).to_a
  end

  def test_or_without_left_where
    expected = Post.all.to_a
    assert_equal expected, Post.or(Post.where('id = 1')).to_a
  end

  def test_or_without_right_where
    expected = Post.all.to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('')).to_a
  end
#--------------------------------
#  test other gem
#--------------------------------
  def test_if_method_all_return_array #EX: gem activerecord-deprecated_finders will change #all in Rails 4
    expected = Post.where('id = 1 or id = 2').to_a
    p1 = Post.where(:id => 1)
    p2 = Post.where(:id => 2)
    def p1.all ; super.to_a ; end
    def p2.all ; super.to_a ; end
    assert_equal expected, p1.or(p2).to_a
  end

  def test_or_with_left_be_none
    none1 = User.where('0')
    none2 = User.none if User.respond_to?(:none)
    pearl = User.where(name: 'Pearl')

    assert_equal pearl.pluck(:id), none1.or(pearl).pluck(:id)
    assert_equal pearl.pluck(:id), none2.or(pearl).pluck(:id) if none2
  end

  def test_or_with_right_be_none
    none1 = User.where('0')
    none2 = User.none if User.respond_to?(:none)
    pearl = User.where(name: 'Pearl')

    assert_equal pearl.pluck(:id), pearl.or(none1).pluck(:id)
    assert_equal pearl.pluck(:id), pearl.or(none2).pluck(:id) if none2
  end
end
