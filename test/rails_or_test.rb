require 'test_helper'

class RailsOrTest < Minitest::Test
  def setup
    
  end
  def test_that_it_has_a_version_number
    refute_nil ::RailsOr::VERSION
  end
  def test_or_with_relation
    expected = Post.where('id = 1 or id = 2').to_a
    assert_equal expected, Post.where('id = 1').or(Post.where('id = 2')).to_a
  end
end
