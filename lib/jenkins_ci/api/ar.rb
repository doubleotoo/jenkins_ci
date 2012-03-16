require 'logger'

require 'active_record'

load 'jenkins.rb'
load 'project.rb'
load 'view.rb'

$logger = Logger.new(STDERR)
$logger.level = Logger::INFO
ActiveRecord::Base.logger = $logger
#ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
    :adapter  => "sqlite3",
    :database => "tmp.sqlite3"
    #:database => ":memory:"
)

#ActiveRecord::Schema.define do
#    #create_table :projects, :force => true do |table|
#    create_table :projects do |table|
#        table.column :project_name,   :string,
#                                      :presence => true,
#                                      :uniqueness => true
#        table.column :url,            :string
#    end
#
#    create_table :builds do |table|
#        table.column :project_name, :string
#        table.column :number,   :integer
#        table.column :building, :boolean
#        table.column :url,      :string
#        table.column :result,   :string
#        table.column :branch,   :string
#        table.column :sha1,     :string
#    end
#end

module DB
  class Project < ActiveRecord::Base
      has_many :builds, :primary_key => :project_name, :foreign_key => :project_name

      def last_build
        builds.find(:first, :order => 'number DESC', :limit => 1)
      end

      def find_build(number)
        builds.find_by_number(number)
      end

      def to_s
        "<Project('#{project_name}|#{url}')>"
      end
  end

  class Build < ActiveRecord::Base
      belongs_to :project, :foreign_key => :name

      def to_s
        "<Build('#{project_name}|#{number}|#{building}|#{url}|#{result}|#{branch}|#{sha1}')>"
      end
  end
end

module CI
module Jenkins
end
end

#sqlite> select sha1, branch, project_name, number, result from builds where branch not null order by branch, sha1, project_name, number;

$verbose = true
jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
v = CI::Jenkins::View.create('Integration', jenkins, exclude_projects=['C0-Poll', 'C0-Queue'])


#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
#v = CI::Jenkins::View.create('All', jenkins)

