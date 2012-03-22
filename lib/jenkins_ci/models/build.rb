require 'active_record'

module CI
module Jenkins
module DB
class Build < ActiveRecord::Base
  set_table_name :builds

  BOOLEAN = [true, false]

  SUCCESS = 'SUCCESS'
  FAILURE = 'FAILURE'
  ABORTED = 'ABORTED'
  RESULTS = [SUCCESS, FAILURE, ABORTED]

  REGEXP_GIT_SHA1   = Regexp.new(/^[0-9a-f]{40}$/)
  REGEXP_GIT_BRANCH = Regexp.new(/^.+-rc$/)
  REGEXP_BUILD_URL  = Regexp.new(/^http:\/\/.+\/job\/.+\/\d+(\/)?$/)

  belongs_to :project, :foreign_key => :name

  #-------------------------------------------------------------------------
  #  Validation
  #-------------------------------------------------------------------------
  # (project_name, number) A single project must have unique build numbers.
  validates :project_name,
            :presence => true,
            :uniqueness => {
                :scope => :number,
                :message => 'Composite key (project_name, number) isalready taken'}

  validates :number,
            :presence => true,
            :numericality => {
                :only_integer => true,
                :greater_than => 0 }

  validates :building,
            :inclusion => {
                :in => BOOLEAN,
                :message => "'%{value}' is not in #{BOOLEAN}" }

  validates :url,
            :presence => true,
            :format => {
                :with => REGEXP_BUILD_URL,
                :message => "'%{value}' is not a valid Jenkins build url, expecting '#{REGEXP_BUILD_URL}'" }

  validates :result,
            :if => Proc.new { |a| not a.building },
            :presence => true,
            :inclusion => {
                :in => RESULTS,
                :message => "'%{value}' is not in #{RESULTS}" }

  validates :sha1,
            :allow_nil => true,
            :format => {
                :with => REGEXP_GIT_SHA1,
                :message => "'%{value}' is not a valid Git SHA1, expecting '#{REGEXP_GIT_SHA1}'" }

  validates :branch,
            :allow_nil => true,
            :format => {
                :with => REGEXP_GIT_BRANCH,
                :message => "'%{value}' is not a valid Git branch, expecting '#{REGEXP_GIT_BRANCH}'" }

  def self.distinct_branches
    Build.find(:all,
        :select => 'distinct branch',
        :conditions => 'branch is not null',
        :order => 'branch asc').collect { |b| b.branch }
  end

  def self.distinct_sha1s
    Build.find(:all,
        :select => 'distinct sha1',
        :conditions => 'sha1 is not null',
        :order => 'sha1 asc').collect { |b| b.sha1 }
  end


  #-------------------------------------------------------------------------
  #  Built-in
  #-------------------------------------------------------------------------
  def to_s
    "<Build('#{project_name}|#{number}|#{building}|#{url}|#{result}|#{branch}|#{sha1}')>"
  end

  #-------------------------------------------------------------------------
  #  API
  #-------------------------------------------------------------------------
end #-end class Build

end #-end module DB
end #-end module Jenkins
end #-end module CI

