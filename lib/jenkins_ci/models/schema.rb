module CI
module Jenkins
module DB

class Schema

  require 'logger'
  require 'active_record'

  def initialize(adapter='sqlite3', database=':memory:', force=true, logger=Logger.new(STDERR))
    @adapter  = adapter
    @database = database
    @force    = force
    @logger   = logger

    ActiveRecord::Base.logger = @logger

    ActiveRecord::Base.establish_connection(
        :adapter  => @adapter,
        :database => @database
    )

    #ActiveRecord::Schema.define do
    #    create_table :projects, :force => @force do |table|
    #        table.column :project_name,   :string,
    #                                      :presence => true,
    #                                      :uniqueness => true
    #        table.column :url,            :string
    #    end

    #    create_table :builds, :force => @force do |table|
    #        table.column :project_name, :string
    #        table.column :number,   :integer
    #        table.column :building, :boolean
    #        table.column :url,      :string
    #        table.column :result,   :string
    #        table.column :branch,   :string
    #        table.column :sha1,     :string
    #    end
    #end
  end
end #-end class Schema 

end #-end module DB
end #-end module Jenkins
end #-end module CI
