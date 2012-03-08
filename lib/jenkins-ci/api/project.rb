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
$: << File.dirname( __FILE__)
load "jenkins.rb"
load "json_resource.rb"

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
#
# Create Project using named constructor +Project.create+.
#
class Project < JsonResource
  attr_reader :name
  @cache = {} # TODO: remove, should be INHERITED from JsonResource < CacheableObject

  def self.create(name, jenkins, lazy_load=false) # TODO: lazy_load=true
    key = generate_cache_key(name)
    @cache[key] ||= new(name, jenkins, lazy_load)
  end

  def self.has_project(name)
    key = generate_cache_key(name)
    @cache.has_key?(key)
  end

  # ==== Arguments
  #  * +name+ is the name of this Jenkins project.
  #  * +jenkins+ is the Jenkins server instance.
  #  * +lazy_load+ indicates whether we should load only
  #    when required.
  #
  # TODO: add stale JSON duration
  #
  def initialize(name, jenkins, lazy_load=true)
    super("/job/#{name}", jenkins, lazy_load)
    @name = name
  end

  def self.get_all(jenkins, lazy_load=true)
    projects = []

    json = jenkins.get_json('', ['tree=jobs[name,url,color]'])
    jobs = json["jobs"]
    jobs.each do |job|
      name = job["name"]
      url = job["url"]
      color = job["color"]

      project = CI::Jenkins::Project.create(name, jenkins, lazy_load)
      projects.push(project)
    end

    return projects
  end

  # TODO: resolve circular dependency otherwise infinite recursion
  # e.g. project A <-> project B
  def to_s
    {
      :name =>  @name,
      :api  =>  instance_variables.collect { |varname|
                  var = self.instance_variable_get(varname) if varname.match(/^@j_/)
                  if var.kind_of?(Array)
                    { varname => "Array<#{var.first.class}>##{var.size}" }
                  elsif not var.nil?
                    { varname => var }
                  else
                    nil
                  end
                }.compact
    }
  end

  DETAIL = {
#   Internal symbol               Jenkins symbol            Description
#   ===============               ==============            ===========
    :j_actions                =>  'action',                 # array
    :j_description            =>  'description',            # html string
    :j_displayName            =>  'displayName',            # string
    :j_name                   =>  'name',                   # string
    :j_url                    =>  'url',                    # string
    :j_buildable              =>  'buildable',              # boolean
    :j_builds                 =>  'builds',                 # array of Build objects
    :j_color                  =>  'color',                  # color (blue, red, yellow, grey)
    :j_firstBuild             =>  'firstBuild',             # Build object
    :j_healthReport           =>  'healthReport',           # HealthReport object
    :j_inQueue                =>  'inQueue',                # boolean
    :j_keepDependencies       =>  'keepDependencies',       # boolean
    :j_lastBuild              =>  'lastBuild',              # Build object
    :j_lastCompletedBuild     =>  'lastCompletedBuild',     # Build object
    :j_lastFailedBuild        =>  'lastFailedBuild',        # Build object
    :j_lastStableBuild        =>  'lastStableBuild',        # Build object
    :j_lastSuccessfulBuild    =>  'lastSuccessfulBuild',    # Build object
    :j_lastUnstableBuild      =>  'lastUnstableBuild',      # Build object
    :j_lastUnsuccessfulBuild  =>  'lastUnsuccessfulBuild',  # Build object
    :j_nextBuildNumber        =>  'nextBuildNumber',        # integer
    :j_property               =>  'property',               # array of ?
    :j_queueItem              =>  'queueItem',              # ?
    :j_concurrentBuild        =>  'concurrentBuild',        # boolean
    :j_downstreamProjects     =>  'downstreamProjects',     # array of Project objects
    :j_scm                    =>  'scm',                    # ?
    :j_upstreamProjects       =>  'upstreamProjects',       # array of Project objects
    :j_activeConfigurations   =>  'activeConfigurations'    # array of Project objects
  }

end #-end class Project
end #-end module Jenkins
end #-end module CI

