require 'helper'

# TODO: depends on the jenkins instance 
class TestGetOne < CI::Jenkins::TestCase

  def setup
    CI::Jenkins::TestCase.instance_method(:setup).bind(self).call
    @project1 = CI::Jenkins::Project.create('a00-commit', @jenkins, false)
    @project2 = CI::Jenkins::Project.create('a00-ROSE-from-scratch', @jenkins, false)
    @project3 = CI::Jenkins::Project.create('enable-only', @jenkins, false)
    @project4 = CI::Jenkins::Project.create('zz-Commit', @jenkins, false)
  end

  def test_nil
    assert_not_nil(@project1)
    assert_not_nil(@project2)
    assert_not_nil(@project3)
    assert_not_nil(@project4)
  end

  def test_downstreamProjects
    assert_equal(2, @project1.j_downstreamProjects.size)
    assert_equal(1, @project2.j_downstreamProjects.size)
    assert_equal(1, @project3.j_downstreamProjects.size)
    assert_equal(0, @project4.j_downstreamProjects.size)

    @project1.j_downstreamProjects.each do |proj|
        assert([@project2.j_name, @project3.j_name].include?(proj.j_name),
                'unexpected downstream job')
    end

    @project2.j_downstreamProjects.each do |proj|
        assert_equal(@project4.j_name, proj.j_name)
    end

    @project3.j_downstreamProjects.each do |proj|
        assert_equal(@project4.j_name, proj.j_name)
    end
  end

  def test_upstreamProjects
    assert_equal(0, @project1.j_upstreamProjects.size)
    assert_equal(1, @project2.j_upstreamProjects.size)
    assert_equal(1, @project3.j_upstreamProjects.size)
    assert_equal(2, @project4.j_upstreamProjects.size)
puts
puts @project4.j_upstreamProjects
    @project4.j_upstreamProjects.each do |proj|
        assert([@project2.j_name, @project3.j_name].include?(proj.j_name),
                'unexpected upstream job')
    end
  end

end


