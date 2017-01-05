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
#  Multiple columns
#--------------------------------
  def test_or_with_multiple_attributes
    expected = Post.where('id = 1 or title = ?', "Kathenrie's post1").to_a
    assert_equal expected, Post.where('id = 1').or(:title => "Kathenrie's post1").to_a
  end
#--------------------------------
#  logic order
#--------------------------------
  def test_A_and_B_or_C #(A && B) || C
    expected = Post.where('(user_id = ? AND title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
    assert_equal expected, Post.where(:user_id => 1).where(:title => "John's post1").or(:user_id => 2).to_a
  end
  def test_A_or_B_and_C #(A || B) && C
    expected = Post.where('(user_id = ? OR user_id = ?) AND title LIKE ?', 1, 2, "John's %").to_a
    assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where('title LIKE ?', "John's %").to_a
  end
  if Gem::Version.new(Rails::VERSION::STRING) > Gem::Version.new('4.0.2')
    def test_A_and_not_B_or_C #(A && !B) || C
      expected = Post.where('(user_id = ? AND NOT title = ?) OR user_id = ?', 1, "John's post1", 2).to_a
      assert_equal expected, Post.where(:user_id => 1).where.not(:title => "John's post1").or(:user_id => 2).to_a
    end
    def test_A_or_B_and_not_C #(A || B) && !C
      expected = Post.where('(user_id = ? OR user_id = ?) AND title NOT LIKE ?', 1, 2, "John's %").to_a
      assert_equal expected, Post.where(:user_id => 1).or(:user_id => 2).where.not('title LIKE ?', "John's %").to_a
    end
  end
  def test_A_and_not_B_or_not_C #(A && !B) || !C
    expected = Post.where('(user_id != ? AND title LIKE ?) OR title NOT LIKE ?', 1, "Kathenrie's %", "Pearl's %").to_a
    assert_equal expected, Post.where.not(:user_id => 1).where('title LIKE ?', "Kathenrie's %").or_not('title LIKE ?', "Pearl's %").to_a
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
