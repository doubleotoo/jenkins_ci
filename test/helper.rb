$: << "/Users/too1/Development/projects/ruby/jenkins/lib"
require 'jenkins-ci'
require 'test/unit'

unless RUBY_VERSION >= "1.9"
  require 'iconv'
end

module CI
module Jenkins
  class TestCase < Test::Unit::TestCase
    unless RUBY_VERSION >= '1.9'
      undef :default_test
    end

    def setup
      @jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
    end
  end
end
end

