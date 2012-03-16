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
$: << File.dirname( __FILE__)
load "jenkins.rb"
load "json_resource.rb"

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
    begin
        o = DB::Build.find_by_project_name_and_number!(project.name, number)
    rescue ActiveRecord::RecordNotFound
        key = generate_cache_key(number.to_s, project.name)
        o = @cache[key] ||= new(number, project, jenkins)

        o = DB::Build.create(:project_name  => project.name,
                             :number        => number,
                             :url           => o.j_url,
                             :branch        => branch(o.j_description),
                             :sha1          => sha1(o.j_description),
                             :result        => o.j_result)
    end
    return o
  end

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
            'tree=number,description,url,result'])
    end
  end

  # Setup this Resource with its corresponding Jenkins JSON.
  def sync
      puts "Syncing #{@path}" if $verbose
      @json = get_json

      @json.each do |key, value|
        puts "Build::#{key}"
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

  #-----------------------------------------------------------------------------
  #  API
  #-----------------------------------------------------------------------------

  # Return a summary of this Build.
  #
  # To improve performance, we will fetch only summary information if
  # this Build object has not yet been synced. This is opposed to
  # performing a full-blown sync.
  def summary
    if not @synced or (
        @j_number.nil? or @j_description.nil? or @j_result.nil? or @j_building.nil?
    )
      build_summary = JsonResource.create(
                          "/job/#{@project.name}/#{@number}",
                          @jenkins,
                          lazy_load=false,
                          parameters=['tree=number,building,result,description'])
      @j_number       = build_summary.j_number
      @j_description  = build_summary.j_description
      @j_result       = build_summary.j_result
      @j_building     = build_summary.j_building
    end
    return {
        :j_number       => @j_number,
        :j_description  => @j_description,
        :j_result       => @j_result,
        :j_building     => @j_building
    }
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

