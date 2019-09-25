require 'test_helper'

class RailsOrTest < Minitest::Test
  def setup
  end

  def test_that_it_has_a_version_number
    refute_nil ::RailsOr::VERSION
  end

  # ----------------------------------------------------------------
  # ● Parameter check
  # ----------------------------------------------------------------
  def test_or_with_model1
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 2')).to_a
  end

  def test_or_with_model2
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where(id: 1).or(Post.where(id: 2)).to_a
  end

  def test_or_with_string_argument
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or('id = 2').to_a
  end

  def test_or_with_hash_argument
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(id: 2).to_a
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

  # ----------------------------------------------------------------
  # ● Common condition
  # ----------------------------------------------------------------
  def test_or_with_shared_where
    expected = Post.where('id = 1 and (title = ? or title = ?)', "John's post1", "John's post2").to_a
    target = Post.where('id = 1').where(title: "John's post1").or(Post.where('id = 1').where(title: "John's post2"))
    assert_equal expected, target.to_a

    version = Gem::Version.new(ActiveRecord::VERSION::STRING)
    expected = case
               when version < Gem::Version.new('5.0.0') ; 1 # In Rails 3, 4, use #or method that `rails_or` provides. It will merge same condition.
               when version < Gem::Version.new('5.2.0') ; 2 # In Rails 5, use native #or method, which doesn't merge same condition.
               else                                     ; 1 # In Rails 5.2, the issue is fixed, see: https://github.com/rails/rails/pull/29950
               end
    assert_equal expected, target.to_sql.scan('id = 1').size
  end

  def test_or_with_shared_where_and_binding_values
    p1 = Post.where(id: 1)
    expected = p1.where('title = ? or title = ?', "John's post1", "John's post2").to_a
    target = p1.where(title: "John's post1").or(p1.where(title: "John's post2"))
    assert_equal expected, target.to_a
  end

  def test_or_with_unneeded_brackets
    # Wrong: SELECT "users".* FROM "users"  WHERE (("users"."id" = 1) OR ("users"."id" = 2))
    # Correct: SELECT "users".* FROM "users"  WHERE ("users"."id" = 1 OR "users"."id" = 2)
    assert_equal 1, User.where(id: 1).or(id: 2).to_sql.count('(')
  end

  # ----------------------------------------------------------------
  # ● Multiple columns
  # ----------------------------------------------------------------
  def test_or_with_multiple_attributes
    expected = Post.where('id = 1 or title = ?', "Doggy's post1").to_a
    assert_equal expected, Post.where('id = 1').or(title: "Doggy's post1").to_a
  end

  # ----------------------------------------------------------------
  # ● join
  # ----------------------------------------------------------------
  def test_or_with_join
    expected = User.joins(:posts).where('user_id = 1 AND (title = ? OR title = ? OR title = ?)', "John's post1", "John's post2", "John's post3").to_a
    assert_equal expected, User.joins(:posts).where('0')
                               .or(id: 1, 'posts.title': "John's post1")
                               .or(id: 1, 'posts.title': "John's post2")
                               .or(id: 1, 'posts.title': "John's post3")
                               .to_a
  end

  def test_or_with_join_and_no_join
    expected = User.joins(:posts).where('user_id = 1 AND title = ? OR user_id = 2', "John's post2").to_a
    assert_equal expected, User.joins(:posts).where(id: 1, 'posts.title': "John's post2").or(id: 2).to_a
  end

  # ----------------------------------------------------------------
  # ● having
  # ----------------------------------------------------------------
  def test_or_with_having
    expected = Post.group(:user_id).having('COUNT(*) = 1 OR COUNT(*) = 2').to_a
    assert_equal expected, Post.group(:user_id).having('COUNT(*) = 1').or(Post.group(:user_id).having('COUNT(*) = 2')).to_a
    assert_equal expected, Post.group(:user_id).having('COUNT(*) = 1').or_having('COUNT(*) = 2').to_a
  end

  def test_or_with_join_and_having
    expected = User.joins(:posts).group(:user_id).having('COUNT(*) = 1 OR COUNT(*) > 1').to_a
    assert_equal expected, User.joins(:posts).group(:user_id).having('COUNT(*) > 1').or_having('COUNT(*) = 1').to_a
  end

  # ----------------------------------------------------------------
  # ● uniq / limit / offset / order
  # ----------------------------------------------------------------
  def test_or_with_limit
    expected = Post.where('user_id = 1 OR user_id = 2').limit(4).to_a
    assert_equal expected, Post.limit(4).where(user_id: 1).or(user_id: 2).to_a
  end

  def test_or_with_uniq
    posts = (Post.respond_to?(:distinct) ? Post.distinct : Post.uniq)
    expected = posts.where('user_id = 1 OR user_id = 2').pluck(:user_id)
    assert_equal expected, posts.where(user_id: 1).or(user_id: 2).pluck(:user_id)
  end

  def test_or_with_offset
    expected = Post.where('user_id = 1 OR user_id = 2').offset(3).first
    assert_equal expected, Post.offset(3).where(user_id: 1).or(user_id: 2).first
  end

  def test_or_with_order
    expected = Post.where('user_id = 1 OR user_id = 2 OR user_id = 3').order('user_id desc').pluck(:user_id)
    assert_equal expected, Post.order('user_id desc').where(user_id: 1).or(user_id: 2).or(user_id: 3).pluck(:user_id)
  end

  # ----------------------------------------------------------------
  # ● logic order
  # ----------------------------------------------------------------
  def test_A_and_B_or_C # (A && B) || C, C || (B && A)
    expected = Post.where('(user_id = ? AND title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
    assert_equal expected, Post.where(user_id: 1).where(title: "John's post1").or(user_id: 2).to_a
    assert_equal expected, Post.where(user_id: 2).or(Post.where(title: "John's post1").where(user_id: 1)).to_a
  end

  def test_A_or_B_and_C # (A || B) && C
    expected = Post.where('(user_id = ? OR user_id = ?) AND title LIKE ?', 1, 2, "John's %").to_a
    assert_equal expected, Post.where(user_id: 1).or(user_id: 2).where('title LIKE ?', "John's %").to_a
  end

  if Gem::Version.new(ActiveRecord::VERSION::STRING) > Gem::Version.new('4.0.2')
    def test_A_and_not_B_or_C # (A && !B) || C, C || (!B && A)
      expected = Post.where('(user_id = ? AND NOT title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
      assert_equal expected, Post.where(user_id: 1).where.not(title: "John's post1").or(user_id: 2).to_a
      assert_equal expected, Post.where(user_id: 2).or(Post.where.not(title: "John's post1").where(user_id: 1)).to_a
    end

    def test_A_or_B_and_not_C # (A || B) && !C
      expected = Post.where('(user_id = ? OR user_id = ?) AND title NOT LIKE ?', 1, 2, "John's %").to_a
      assert_equal expected, Post.where(user_id: 1).or(user_id: 2).where.not('title LIKE ?', "John's %").to_a
    end

    def test_A_and_not_B_or_not_C # (A && !B) || !C, !C || (!B && A)
      expected = Post.where('(title LIKE ? AND user_id != ?) OR title NOT LIKE ?', 1, "Doggy's %", "Pearl's %").to_a
      assert_equal expected, Post.where('title LIKE ?', "Doggy's %").where.not(user_id: 1).or_not('title LIKE ?', "Pearl's %").to_a
      assert_equal expected, Post.where.not('title LIKE ?', "Pearl's %").or(Post.where.not(user_id: 1).where('title LIKE ?', "Doggy's %")).to_a
    end
  end

  # ----------------------------------------------------------------
  # ● Nested
  # ----------------------------------------------------------------
  def test_nested_or # (A && (B || C)) || D, ((B || C) && A) || D
    expected = Post.where('(title like ?) AND (start_time IS NULL OR start_time > ?) OR (title = ?)', 'John%', Time.parse('2016/1/15'), "Pearl's post1").pluck(:title)
    p1 = Post.with_title_like('John%').where('start_time IS NULL OR start_time > ?', Time.parse('2016/1/15'))
    assert_equal expected, p1.or(title: "Pearl's post1").pluck(:title)

    p1 = Post.where(start_time: nil).or('start_time > ?', Time.parse('2016/1/15')).with_title_like('John%')
    assert_equal expected, p1.or(title: "Pearl's post1").pluck(:title)
  end

  # ----------------------------------------------------------------
  # ● Association test
  # ----------------------------------------------------------------
  def test_two_has_many_result # model.others1 || model.others2
    user = User.where(name: 'John').first
    assert_equal user.sent_messages.or(user.received_messages).pluck(:content), [
      'user1 send to user2',
      'user1 send to user3',
      'user3 send to user1',
    ]
  end

  # ----------------------------------------------------------------
  # ● Scope test
  # ----------------------------------------------------------------
  def test_two_scope
    u1 = User.where(name: 'John').first
    u2 = User.where(name: 'Pearl').first
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

  # ----------------------------------------------------------------
  # ● From Rails 5
  # ----------------------------------------------------------------
  def test_or_with_relation
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 2')).to_a
  end

  def test_or_identity
    expected = Post.where('id = 1').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 1')).to_a
    assert_equal expected, Post.where(id: 1).or(Post.where('id = 1')).to_a
  end

  def test_or_without_left_where
    expected = Post.all.to_a
    assert_equal expected, Post.or(Post.where('id = 1')).to_a
  end

  def test_or_without_right_where
    expected = Post.all.to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('')).to_a
  end

  def test_or_preserves_other_querying_methods
    expected = Post.where('id = 1 or id = 2 or id = 3').order('title asc').to_a
    partial = Post.order('title asc')
    assert_equal expected, partial.where('id = 1').or(partial.where(id: [2, 3])).to_a
    assert_equal expected, Post.order('title asc').where('id = 1').or(Post.order('title asc').where(id: [2, 3])).to_a
  end

  def test_or_on_loaded_relation
    expected = Post.where('id = 1 or id = 2').to_a
    p = Post.where('id = 1')
    p.map(&:id) # p.load # Rails 3 doesn't have load method
    assert_equal p.loaded?, true
    assert_equal expected, p.or(Post.where('id = 2')).to_a
  end

  # ----------------------------------------------------------------
  # ● test other gem
  # ----------------------------------------------------------------
  def test_if_method_all_return_array # EX: gem activerecord-deprecated_finders will change #all in Rails 4
    expected = Post.where('id = 1 or id = 2').to_a
    p1 = Post.where(id: 1)
    p2 = Post.where(id: 2)
    def p1.all
      super.to_a
    end

    def p2.all
      super.to_a
    end
    assert_equal expected, p1.or(p2).to_a
  end

  def test_or_with_left_be_none
    pearl = User.where(name: 'Pearl')
    assert_equal pearl.pluck(:id), User.none.or(pearl).pluck(:id)
  end

  def test_or_with_right_be_none
    pearl = User.where(name: 'Pearl')
    assert_equal pearl.pluck(:id), pearl.or(User.none).pluck(:id)
  end

  def test_or_with_from
    users = User.from(User.where(name: %w[John Pearl]))
    user1 = users.where('subquery.name' => 'Doggy')
    user2 = users.where('subquery.name' => 'Pearl')
    user1_or_2 = user1.or('subquery.name' => 'Pearl')
    assert_equal ['Pearl'], user1.or(user2).pluck('subquery.name')
    assert_equal ['Pearl'], user1_or_2.pluck('subquery.name')
  end

  def test_or_with_from_and_none
    users = User.from(User.where(name: %w[John Pearl]))
    user1 = users.where('subquery.name' => 'Doggy').none
    user2 = users.where('subquery.name' => 'Pearl')
    user1_or_2 = user1.or('subquery.name' => 'Pearl')
    assert_equal ['Pearl'], user1.or(user2).pluck('subquery.name')
    assert_equal ['Pearl'], user1_or_2.pluck('subquery.name')
  end
end
