require 'logger'

require 'active_record'

load 'jenkins.rb'
load 'project.rb'
load 'view.rb'

$logger = Logger.new(STDERR)
#$logger.level = Logger::INFO
ActiveRecord::Base.logger = $logger
#ActiveRecord::Base.colorize_logging = false

ActiveRecord::Base.establish_connection(
    :adapter  => "sqlite3",
    :database => "tmp.sqlite3"
    #:database => ":memory:"
)

ActiveRecord::Schema.define do
    create_table :projects, :force => true do |table|
    #create_table :projects do |table|
        table.column :project_name,   :string,
                                      :presence => true,
                                      :uniqueness => true
        table.column :url,            :string
    end

    create_table :builds, :force => true do |table|
    #create_table :builds do |table|
        table.column :project_name, :string
        table.column :number,   :integer
        table.column :building, :boolean
        table.column :url,      :string
        table.column :result,   :string
        table.column :branch,   :string
        table.column :sha1,     :string
    end

    #add a foreign key
    execute <<-SQL
      PRAGMA foreign_keys = ON;

      CREATE TABLE builds (

        project_name  VARCHAR(255) NOT NULL,
        number        INTEGER NOT NULL,
        building      BOOLEAN,
        url           VARCHAR(255),
        result        VARCHAR(16),
        branch        VARCHAR(255),
        sha1          VARCHAR(40),

        PRIMARY KEY (project_name, number)
        FOREIGN KEY (project_name) REFERENCES projects(project_name)
      )
    SQL
end

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

      #-------------------------------------------------------------------------
      #  Validation
      #-------------------------------------------------------------------------
      validates :url,                                                                         
                :presence => true,                                                            
                :uniqueness => true,
                :format => {                                                                  
                    :with => /^http:\/\/.+\/job\/.+(\/)?$/,                                   
                    :message => "Invalid Jenkins Project url '%{value}'" }
  end

  class Build < ActiveRecord::Base
      belongs_to :project, :foreign_key => :name
      #validates_uniqueness_of :id, :scope => [:project_name, :number]
      #validates_uniqueness_of :project_name, :number
      #validates :id, :uniqueness => {:scope => [:project_name, :number]}
      validates :project_name, :uniqueness => {:scope => [:number]}

      def to_s
        "<Build('#{project_name}|#{number}|#{building}|#{url}|#{result}|#{branch}|#{sha1}')>"
      end
  end
end

module CI
module Jenkins
end
end

b = DB::Build.create(:project_name => 'C0-Start', :number => 1)
puts b.valid?
puts b.errors
b = DB::Build.create(:project_name => 'C0-Start', :number => 1)
puts b.valid?
puts b.errors.full_messages
b = DB::Build.create(:project_name => 'C0-Start2', :number => 1)
puts b.valid?
puts b.errors.full_messages

#sqlite> select sha1, branch, project_name, number, result from builds where branch not null order by branch, sha1, project_name, number;

#$verbose = true
#jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
#v = CI::Jenkins::View.create('Integration', jenkins, exclude_projects=['C0-Poll', 'C0-Queue'])



#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
#v = CI::Jenkins::View.create('All', jenkins)

