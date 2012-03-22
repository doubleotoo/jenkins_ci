# project.rb
#
# Base Jenkins Project instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
require 'jenkins_ci/api/build.rb'
require 'jenkins_ci/api/json_resource.rb'
require 'jenkins_ci/models/project.rb'

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins

#
# Jenkins Project from JSON.
#
#  DETAIL = {
#   Internal symbol               Jenkins symbol            Description
#   ===============               ==============            ===========
#    :j_actions                =>  'action',                 # array
#    :j_description            =>  'description',            # html string
#    :j_displayName            =>  'displayName',            # string
#    :j_name                   =>  'name',                   # string
#    :j_url                    =>  'url',                    # string
#    :j_buildable              =>  'buildable',              # boolean
#    :j_builds                 =>  'builds',                 # array of Build objects
#    :j_color                  =>  'color',                  # color (blue, red, yellow, grey)
#    :j_firstBuild             =>  'firstBuild',             # Build object
#    :j_healthReport           =>  'healthReport',           # HealthReport object
#    :j_inQueue                =>  'inQueue',                # boolean
#    :j_keepDependencies       =>  'keepDependencies',       # boolean
#    :j_lastBuild              =>  'lastBuild',              # Build object
#    :j_lastCompletedBuild     =>  'lastCompletedBuild',     # Build object
#    :j_lastFailedBuild        =>  'lastFailedBuild',        # Build object
#    :j_lastStableBuild        =>  'lastStableBuild',        # Build object
#    :j_lastSuccessfulBuild    =>  'lastSuccessfulBuild',    # Build object
#    :j_lastUnstableBuild      =>  'lastUnstableBuild',      # Build object
#    :j_lastUnsuccessfulBuild  =>  'lastUnsuccessfulBuild',  # Build object
#    :j_nextBuildNumber        =>  'nextBuildNumber',        # integer
#    :j_property               =>  'property',               # array of ?
#    :j_queueItem              =>  'queueItem',              # ?
#    :j_concurrentBuild        =>  'concurrentBuild',        # boolean
#    :j_downstreamProjects     =>  'downstreamProjects',     # array of Project objects
#    :j_scm                    =>  'scm',                    # ?
#    :j_upstreamProjects       =>  'upstreamProjects',       # array of Project objects
#    :j_activeConfigurations   =>  'activeConfigurations'    # array of Project objects
#  }
class Project < JsonResource
  class << self; attr_accessor :cache end
  @cache = {}

  attr_reader :name

  # Returns a CI::Jenkins::DB::Project (ActiveRecord object)
  def self.create(name, jenkins)
    begin
        o = CI::Jenkins::DB::Project.find_by_project_name!(name)

        # * sync with remote Json source
        # * update builds
        #
        p = Project.new(name, jenkins)
        #o.<attr> = p.j_<attr>
        #o.save
        #o.logger.info "updated #{o.to_s}"
    rescue ActiveRecord::RecordNotFound
        key = generate_cache_key(name)
        # Don't want to create again...
        # 1. Insert with name
        # 2. Fetch JSON
        # 3. Update with extra JSON fields
        ActiveRecord::Base.transaction(:requires_new => true) do
            o = CI::Jenkins::DB::Project.create(:project_name => name)

            json = @cache[key] ||= new(name, jenkins)

            if not name == json.j_name
              raise "Inconsistent data: JSON::name=#{json.j_name}, expected_name=#{name}"
            end

            o.url       = json.j_url
            o.save!
            $logger.info "created #{o.to_s}"
        end
    end
    return o
  end

  # ==== Arguments
  #  * +name+ is the name of this Jenkins project.
  #  * +jenkins+ is the Jenkins server instance.
  #
  def initialize(name, jenkins)
    if name.nil?
        raise "NilError: name=#{name}"
    else
        # TODO: avoid infinite recursion – cleaner way?
        key = JsonResource.generate_cache_key(name)
        Project.cache[key] = self

        @name = name
        super("/job/#{name}", jenkins, parameters=[
            'tree=name,url,builds[number]'])
    end
  end

  # Setup this Resource with its corresponding Jenkins JSON.
  def sync
      $logger.debug "Syncing #{@path}"
      @json = get_json

      @json.each do |key, value|
        $logger.debug "Project::#{key}=#{value}"
        case key
        #---- Builds
        when 'builds'
          builds = []
          value.each do |build|
            build = CI::Jenkins::Build.create(build['number'], self, @jenkins)
            builds.push(build)
          end
          value = builds
        #when 'firstBuild',
        #     'lastBuild',
        #     'lastCompletedBuild',
        #     'lastFailedBuild',
        #     'lastStableBuild',
        #     'lastSuccessfulBuild',
        #     'lastUnstableBuild',
        #     'lastUnsuccessfulBuild'
        #  build = value
        #  unless build.nil?
        #    build = CI::Jenkins::Build.create(build["number"], self, @jenkins)
        #    value = build
        #  end
        #---- Upstream and Downstream Projects
        #when 'downstreamProjects',
        #     'upstreamProjects'
        #  projects = []
        #  value.each do |project|
        #    project = CI::Jenkins::Project.create(project['name'], @jenkins)
        #    projects.push(project)
        #  end
        #  value = projects
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

end #-end class Project
end #-end module Jenkins
end #-end module CI

