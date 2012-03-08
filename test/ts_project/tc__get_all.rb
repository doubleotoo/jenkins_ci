require 'helper'

# TODO: depends on the jenkins instance 
class TestGetAll < CI::Jenkins::TestCase

  def test_nil
    projects = CI::Jenkins::Project.get_all(@jenkins, false)
    assert_not_nil(projects)
  end

  def test_empty
    projects = CI::Jenkins::Project.get_all(@jenkins, false)
    assert(projects.size() > 0)
  end

  def test_count
    projects = CI::Jenkins::Project.get_all(@jenkins, false)
    assert_equal(4, projects.size)
  end
 
end


