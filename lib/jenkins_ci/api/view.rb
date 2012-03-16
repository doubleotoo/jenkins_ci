# view.rb
#
# Base Jenkins View instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
$: << File.dirname( __FILE__)
load "jenkins.rb"
load "json_resource.rb"
load "project.rb"

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
class View < JsonResource
  class << self; attr_accessor :cache end
  @cache = {}

  attr_reader :name

  # Returns a CI::Jenkins::Project (JSON resource)
  def self.create(name, jenkins, exclude_projects=[])
    key = generate_cache_key(name)
    json = @cache[key] ||= new(name, jenkins, exclude_projects)
  end

  # ==== Arguments
  #  * +name+ is the name of this Jenkins project.
  #  * +jenkins+ is the Jenkins server instance.
  #
  def initialize(name, jenkins, exclude_projects=[])
    if name.nil?
        raise "NilError: name=#{name}"
    else
        @name             = name
        @exclude_projects = exclude_projects
        super("/view/#{name}", jenkins, parameters=[
            'tree=name,jobs[name]'])
    end
  end

  # Setup this Resource with its corresponding Jenkins JSON.
  def sync
      $logger.debug "Syncing #{@path}"
      @json = get_json

      @json.each do |key, value|
        $logger.debug "View::#{key}=#{value}"
        case key
        #---- Jobs
        when 'jobs'
          projects = []
          value.each do |project|
            next if @exclude_projects.include?(project['name'])
            project = CI::Jenkins::Project.create(project['name'], @jenkins)
            projects.push(project)
          end
          value = projects
        end #-end case key

        ############################
        # !! Create the attribute !!
        ############################
        create_attribute("j_#{key}", value)
        ############################
      end #-end @json.each
  end #-end sync

  def <=>(o)
    return self.name <=> o.name
  end
end #-end class View
end #-end module Jenkins
end #-end module CI

