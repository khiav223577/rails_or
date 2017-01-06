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
  def test_or_with_common_where
    expected = Post.where('id = 1 and (title = ? or title = ?)', "John's post1", "John's post2").to_a
    assert_equal expected, Post.where('id = 1').where(:title => "John's post1").or(Post.where('id = 1').where(:title => "John's post2")).to_a
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
  if Gem::Version.new(Rails::VERSION::STRING) < Gem::Version.new('5.0.0')
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
      expected = Post.uniq.where('user_id = 1 OR user_id = 2').pluck(:user_id)
      assert_equal expected, Post.uniq.where(:user_id => 1).or(:user_id => 2).pluck(:user_id)
    end
    def test_or_with_offset #Rails 5 doesn't support this
      expected = Post.where('user_id = 1 OR user_id = 2').offset(3).first
      assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).offset(3).first
    end
    def test_or_with_order #Rails 5 doesn't support this
      expected = Post.where('user_id = 1 OR user_id = 2 OR user_id = 3').order('user_id desc').pluck(:user_id)
      assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).or(:user_id => 3).order('user_id desc').pluck(:user_id)
    end
  end
#--------------------------------
#  logic order
#--------------------------------
  def test_A_and_B_or_C #(A && B) || C, C || (B && A)
    expected = Post.where('(user_id = ? AND title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
    assert_equal expected, Post.where(:user_id => 1).where(:title => "John's post1").or(:user_id => 2).to_a
    assert_equal expected, Post.where(:user_id => 2).or(Post.where(:title => "John's post1").where(:user_id => 1)).to_a
  end
  def test_A_or_B_and_C #(A || B) && C
    expected = Post.where('(user_id = ? OR user_id = ?) AND title LIKE ?', 1, 2, "John's %").to_a
    assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where('title LIKE ?', "John's %").to_a
  end
  if Gem::Version.new(Rails::VERSION::STRING) > Gem::Version.new('4.0.2')
    def test_A_and_not_B_or_C #(A && !B) || C, C || (!B && A)
      expected = Post.where('(user_id = ? AND NOT title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
      assert_equal expected, Post.where(:user_id => 1).where.not(:title => "John's post1").or(:user_id => 2).to_a
      assert_equal expected, Post.where(:user_id => 2).or(Post.where.not(:title => "John's post1").where(:user_id => 1)).to_a
    end
    def test_A_or_B_and_not_C #(A || B) && !C
      expected = Post.where('(user_id = ? OR user_id = ?) AND title NOT LIKE ?', 1, 2, "John's %").to_a
      assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where.not('title LIKE ?', "John's %").to_a
    end
    def test_A_and_not_B_or_not_C #(A && !B) || !C, !C || (!B && A)
      expected = Post.where('(title LIKE ? AND user_id != ?) OR title NOT LIKE ?', 1, "Kathenrie's %", "Pearl's %").to_a
      assert_equal expected, Post.where('title LIKE ?', "Kathenrie's %").where.not(:user_id => 1).or_not('title LIKE ?', "Pearl's %").to_a
      assert_equal expected, Post.where.not('title LIKE ?', "Pearl's %").or(Post.where.not(:user_id => 1).where('title LIKE ?', "Kathenrie's %")).to_a
    end
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
end
