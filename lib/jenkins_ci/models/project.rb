require 'active_record'

module CI
module Jenkins
module DB
class Project < ActiveRecord::Base
  set_table_name :projects

  REGEXP_JOB_URL = Regexp.new(/^http:\/\/.+\/job\/.+(\/)?$/)

  has_many  :builds,
            :primary_key => :project_name,
            :foreign_key => :project_name

  #-------------------------------------------------------------------------
  #  Validation
  #-------------------------------------------------------------------------
  validates :url,
            :presence => true,
            :uniqueness => true,
            :format => {
                :with => REGEXP_JOB_URL,
                :message => "'%{value}' is not a valid Jenkins project " +
                            "url, expecting #{REGEXP_JOB_URL}" }

  #-------------------------------------------------------------------------
  #  Built-in
  #-------------------------------------------------------------------------
  def to_s
    "<Project('#{project_name}|#{url}')>"
  end

  #-------------------------------------------------------------------------
  #  API
  #-------------------------------------------------------------------------
  def last_build
    builds.find(:first, :order => 'number DESC', :limit => 1)
  end

  def first_build
    builds.find(:first, :order => 'number ASC', :limit => 1)
  end

  def find_build(number)
    builds.find_by_number(number)
  end
end #-end class Project

end #-end module DB
end #-end module Jenkins
end #-end module CI

