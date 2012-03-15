# project.rb
#
# Base Jenkins Project instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

# Note: we could use /api/json?depth=100000 to get bulk data

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
$: << File.dirname( __FILE__)
require "jenkins.rb"
require "cached_object.rb"
require "project.rb"
require "build.rb"
require "user.rb"
require "queue_item.rb"
require "result.rb"

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins

# TODO: add lazy_load, :synced
class JsonResource < CI::Jenkins::CacheableObject

# TODO: use DETAIL for validation?
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

  attr_reader :path,  # resource path, e.g. '/job/C0-Start'
              :json,
              :synced,
              :jenkins
  @cache = {}

  def self.create(path, jenkins, lazy_load=true, parameters=[])
    key = generate_cache_key(path)
    @cache[key] ||= new(path, jenkins, lazy_load, parameters)
  end

  def initialize(path, jenkins, lazy_load=true, parameters=[])
    if path.nil? or jenkins.nil?
      raise "NilError"
    end
    @path     = path
    @jenkins  = jenkins
    @synced   = false
    @parameters = parameters
    sync() unless lazy_load
  end

  def print_api
    api = instance_variables.collect { |var|
      var if var.match(/^@j_/)
    }.compact
    puts api.join(', ')
  end

  #def to_s
  #  api = instance_variables.collect do |var|
  #    { var => self.instance_variable_get(var) }
  #  end
  #  api.compact
  #end

  # Setup this Resource with its corresponding Jenkins JSON.
  #
  # ==== Arguments
  #
  # * +use_cached+ indicates if we should use a cached copy of this
  #   Resource's JSON, if available.
  #
  # Returns this Project's JSON string.
  #
  def sync(use_cached=false)
    if not @synced
      puts "Syncing #{@path}" if $verbose
      @json = get_json(use_cached)

      @json.each do |key, value|
        # NOTE: infinite recursion problem unless we cache results;
        # project A downstreamProjects> ... project B upstreamProjects> ... project A
        case key
        #---- Builds
        when 'builds'
          builds = []
          value.each do |build|
            build = CI::Jenkins::Build.create_from_json(build, @jenkins)
            builds.push(build)
          end
          value = builds
        when 'firstBuild',
             'lastBuild',
             'lastCompletedBuild',
             'lastFailedBuild',
             'lastStableBuild',
             'lastSuccessfulBuild',
             'lastUnstableBuild',
             'lastUnsuccessfulBuild'
          build = value
          unless build.nil?
            build = CI::Jenkins::Build.create_from_json(build, @jenkins)
            value = build
          end
        #---- Upstream, Downstream, Projects
        when 'jobs',
             'downstreamProjects',
             'upstreamProjects'
          projects = []
          value.each do |project|
            project = CI::Jenkins::Project.create(project['name'], @jenkins)
            projects.push(project)
          end
          value = projects
        #---- Queue Item (Project)
        when 'queueItem'
          item = value
          unless item.nil?
          value = CI::Jenkins::QueueItem.new(
                      item['blocked'],
                      item['buildable'],
                      item['params'],
                      item['stuck'],
                      item['task'],
                      item['why'],
                      item['buildableStartMilliseconds'])
          end
        #---- Culprits (Users)
        #when 'culprits'
        #  users = []
        #  value.each do |user|
        #    user = CI::Jenkins::User.create(user['fullName'], @jenkins)
        #    users.push(user)
        #  end
        #  value = users
        #---- Result (build)
        when 'result'
          result = value
          value = CI::Jenkins::Result.new(result)
        else
          # raise "unknown attribute '#{key}' with value '#{value}'"
        end #-end case key

        ############################
        # !! Create the attribute !!
        ############################
        create_attribute("j_#{key}", value)
        ############################
      end #-end @json.each

      @synced = true
    end
    return @json
  end #-end sync (use_cached=false)

  # ==== Arguments
  #
  # * +use_cached+ indicates if we should provide a cached copy of this
  #   Resource's JSON, if available.
  #
  # Returns this Resource's JSON string.
  #
  def get_json(use_cached=false)
    if use_cached and not (@json.nil? or @json.empty?)
      return @json
    else
      return @jenkins.get_json(@path, @parameters)
    end
  end

#-------------------------------------------------------------------------------
#  Private
#-------------------------------------------------------------------------------

  def method_missing(meth, *args, &block)
    if meth.to_s =~ /^j_(.+)$/
      sync()
      send(meth, *args, &block)
    else
      super # You *must* call super if you don't handle the
            # method, otherwise you'll mess up Ruby's method
            # lookup.
    end
  end

  # Creates an instance method (per object) so each instance will
  # have its own methods.
  def create_obj_method(name, &block)
    raise "duplicate method '#{name}'" if self.respond_to?(name)
    metaclass = class << self; self; end
    metaclass.send(:define_method, name, &block)
  end

  # Creates an instance variable and its accessor methods (per object).
  #
  # ==== Attributes
  #
  # * +name+ is the identifier for the attribute.
  # * +default=value+ for the attribute.
  # * +writeable+ indicates whether a setter method should be created.
  # * +readable+ indicates whether a getter method should be created.
  #
  def create_attribute(name, default_value=nil, writeable=false, readable=true)
    raise "duplicate attribute '#{name}'" if self.instance_variable_defined?("@#{name}")

    instance_variable_set("@" + name, default_value)

    if writeable
      create_obj_method("#{name}=".to_sym) { |value|
        instance_variable_set("@" + name, value)
      }
    end

    if readable
      create_obj_method(name.to_sym) { instance_variable_get("@" + name) }
    end
  end
end #-end class JsonResource
end #-end module Jenkins
end #-end module CI

