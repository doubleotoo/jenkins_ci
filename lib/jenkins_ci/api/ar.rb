require 'logger'

require 'active_record'

load 'jenkins.rb'
load 'project.rb'
load 'view.rb'

ActiveRecord::Base.logger = Logger.new(STDERR)
#ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
    :adapter  => "sqlite3",
    :database => "tmp.sqlite3"
    #:database => ":memory:"
)

ActiveRecord::Schema.define do
    create_table :projects, :force => true do |table|
        table.column :project_name,   :string,
                                      :presence => true,
                                      :uniqueness => true
        table.column :url,            :string
        table.column :buildable,      :boolean
    end

    create_table :builds, :force => true do |table|
        table.column :project_name, :string
        table.column :number, :integer
        table.column :url,    :string
        table.column :result, :string
        table.column :branch, :string
        table.column :sha1,   :string
    end
end

module DB
  class Project < ActiveRecord::Base
      has_many :builds
  end

  class Build < ActiveRecord::Base
      belongs_to :project, :foreign_key => :name
  end
end

module CI
module Jenkins
end
end

#sqlite> select sha1, branch, project_name, number, result from builds where branch not null order by branch, sha1, project_name, number;

$verbose = true
jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
p = CI::Jenkins::View.create('Integration', jenkins, exclude_projects=['C0-Poll', 'C0-Queue'])


