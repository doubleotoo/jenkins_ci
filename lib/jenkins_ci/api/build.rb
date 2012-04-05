# build.rb
#
# Base Jenkins Project build instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
require 'jenkins_ci/api/json_resource.rb'
require 'jenkins_ci/models/build.rb'

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
#
#  DETAIL = {
#   Internal symbol           Jenkins symbol            Description
#   ===============           ==============            ===========
#    :j_actions          =>    'action',                 # array
#    :j_artifacts        =>    'artifacts',              # array of ?
#    :j_building         =>    'building',               # boolean
#    :j_description      =>    'description',            # string
#    :j_duration         =>    'duration',               # integer
#    :j_fullDisplayName  =>    'fullDisplayName',        # string
#    :j_id               =>    'id',                     # string (e.g. "2011-11-08_18-52-40")
#    :j_keepLog          =>    'keepLog',                # boolean
#    :j_number           =>    'number',                 # integer
#    :j_result           =>    'result',                 # string (SUCCESS, ...)
#    :j_timestamp        =>    'timestamp',              # integer
#    :j_url              =>    'url',                    # string
#    :j_builtOn          =>    'builtOn',                # string (e.g. "hudson-rose-25")
#    :j_changeSet        =>    'changeSet',              # hash { :items => [] }
#    :j_culprits         =>    'culprits'                # array of User objects
#  }
#
class Build < JsonResource
  class << self; attr_accessor :cache end
  @cache = {}

  attr_reader :number,
              :project

  # Create a Build object, loading it with its remote data.
  #
  def self.create(number, project, jenkins)
    key = generate_cache_key(number.to_s, project.name)
    begin
        # If the build exists, it could be stale.
        #
        # For example, when the Build was persisted for the first time,
        # it was still building/queued/etc.
        #
        o = CI::Jenkins::DB::Build.find_by_project_name_and_number!(project.name, number)
        if o.result.nil? or o.building == true or (o.sha1.nil? and not o.result.nil?)
            # sync with remote Json source
            b = @cache[key] = Build.new(number, project, jenkins)

            o.result   = b.j_result
            o.building = b.j_building
            o.branch   = branch(b.j_description)
            o.sha1     = sha1(b.j_description)
            o.save
            o.logger.info "updated #{o.to_s}"
        else
            o.logger.debug "up-to-date #{o.to_s}"
        end
    rescue ActiveRecord::RecordNotFound
        b = @cache[key] ||= new(number, project, jenkins)

        o = CI::Jenkins::DB::Build.create!(:project_name  => project.name,
                             :number        => number,
                             :building      => b.j_building,
                             :url           => b.j_url,
                             :branch        => branch(b.j_description),
                             :sha1          => sha1(b.j_description),
                             :result        => b.j_result)
          
        o.save!
        $logger.info "created #{o.to_s}"
    end #-end begin..rescue
    return o
  end

  # ==== Arguments
  #  * +number+ is the number of this Jenkins Build.
  #  * +project+ is the owning Jenkins project.
  #  * +jenkins+ is the Jenkins server instance.
  #  * +lazy_load+ indicates whether we should load only
  #    when required.
  #
  # TODO: add stale JSON duration
  #
  def initialize(number, project, jenkins)
    if number.nil? or project.nil?
        raise "NilError: number=#{number}, project=#{project}"
    else
        @number   = number 
        @project  = project

        super("/job/#{project.name}/#{number}", jenkins, parameters=[
            'tree=number,description,url,building,result'])
    end
  end

  # Setup this Resource with its corresponding Jenkins JSON.
  def sync
      $logger.debug "Syncing #{@path}"
      @json = get_json

      @json.each do |key, value|
        #$logger.debug "Build::#{key}"
        #case key
        #---- <description>
        #when '<key>',
        #end #-end case key

        ############################
        # !! Create the attribute !!
        ############################
        create_attribute("j_#{key}", value)
        ############################
      end #-end @json.each
  end #-end sync

  def self.branch(description)
    desc = description
    if not desc.nil?
        branch = desc.split[1]
        return branch
    else
        return nil
    end
  end

  def self.sha1(description)
    desc = description
    if not desc.nil?
        sha1 = desc.split[0]
        return sha1
    else
        return nil
    end
  end

  #-----------------------------------------------------------------------------
  #  Built-in
  #-----------------------------------------------------------------------------
  def <=>(o)
    return self.number <=> o.number
  end
end #-end class Build
end #-end module Jenkins
end #-end module CI

