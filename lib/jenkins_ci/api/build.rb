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
class Build < JsonResource

  # http://localhost:8080/job/a00-commit/43/
  # http://localhost:8080/job/<jobname>/<buildnumber>/
  URL_REGEX = Regexp.new(/job\/(?<jobname>.*)\/(?<buildnumber>\d+)\//)

  attr_reader :number,
              :project
  @cache = {} # TODO: remove, should be INHERITED from JsonResource < CacheableObject

  # Create a Build object, loading it with its remote data.
  #
  def self.create(number, project, jenkins, lazy_load=true)
    key = generate_cache_key(project.name, number.to_s)
    @cache[key] ||= new(number, project, jenkins, lazy_load)
  end

  # Create a Build object tied to its associated Project from
  # the JSON input information.
  #
  def self.create_from_json(json, jenkins)
    url = json['url']
    buildnumber = json['number']
    if url.nil? or buildnumber.nil?
      raise "Build::NilError! #{json}"
    end
    project_name = CI::Jenkins::Build.parse_jobname(url)
    project = CI::Jenkins::Project.create(project_name, jenkins)
    build = CI::Jenkins::Build.create(buildnumber, project, jenkins)
  end

  def self.parse(url)
    if m = URL_REGEX.match(url)
        return m
    else
        raise "ParseError: malformed Build::url='#{url}'"
    end
  end

  def self.parse_jobname(url)
    return parse(url)[:jobname]
  end

  def self.parse_buildnumber(url)
    return parse(url)[:buildnumber]
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
  def initialize(number, project, jenkins, lazy_load=true)
    super("/job/#{project.name}/#{number}", jenkins, lazy_load)
    @number   = number 
    @project  = project
  end

  # Return this Build's description.
  #
  # To improve performance, we will fetch only the description if
  # this Build object has not yet been synced. This is opposed to
  # performing a full-blown sync.
  def j_description
    if not @synced or @j_description.nil?
      build_desc = JsonResource.create(
                      "/job/#{@project.name}/#{@number}",
                      @jenkins,
                      lazy_load=false,
                      parameters=['tree=description'])
      @j_description = build_desc.j_description
    end
    return @j_description
  end

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

  def to_s
    {
      :project  => @project.name,
      :number   =>  @number,
      :api      =>  instance_variables.collect { |varname|
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

end #-end class Build
end #-end module Jenkins
end #-end module CI

# Example extract of JSON
#
# {"actions":[
#     {"causes":[
#         {"shortDescription":"Started by user hudson-rose",
#          "userName":"hudson-rose"}]},
#     {"buildsByBranchName":
#          "origin/too1-versioning-rc":
#             {"buildNumber":643,
#              "buildResult":null,
#              "revision":
#                 {"SHA1":"2efe7d8bbeab0b0f6676cec671bf98cb6f6ea3e0",
#                  "branch":[
#                     {"SHA1":"2efe7d8bbeab0b0f6676cec671bf98cb6f6ea3e0",
#                      "name":"origin/too1-versioning-rc"}]}},
#      "lastBuiltRevision":
#         {"SHA1":"beae0be1bafeb2f91f0e8785fef8ddff9096969c",
#          "branch":[
#             {"SHA1":"beae0be1bafeb2f91f0e8785fef8ddff9096969c",
#              "name":"origin/cave3-kgs1-branch2-rc"}]}},
#     {},
#     {}],
#   "artifacts": [],
#   "building": false,
#   "description": "beae0be1bafeb2f91f0e8785fef8ddff9096969c",
#   "duration": 8675445,
#   "fullDisplayName": "C0-Start #700 cave3-kgs1-branch2-rc (beae0be1)",
#   "id": "2011-11-08_18-52-40",
#   "keepLog": false,
#   "number": 700,
#   "result": "SUCCESS",
#   "timestamp": 1320807160000,
#   "url": "http://hudson-rose-30.llnl.gov:8080/job/C0-Start/700/",
#   "builtOn": "hudson-rose-27",
#   "changeSet":
#     {"items":[
#         {"author":
#             {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Dan%20Quinlan",
#              "fullName":"Dan Quinlan"},
#          "comment":"Added more support for C++ to ROSE using EDG version 4.3 front-end (60 C++ specific codes now passing, plus all C test codes).\n",
#          "date":"2011-11-07 17:08:18 -0800",
#          "id":"aaef8e64afa911489500716715ff27aff04be54b",
#          "msg":"Added more support for C++ to ROSE using EDG version 4.3 front-end (60 C++ specific codes now passing, plus all C test codes).",
#          "paths":[
#             {"editType":"edit",
#              "file":"src/backend/unparser/nameQualificationSupport.C"},
#             {"editType":"edit",
#              "file":"src/frontend/CxxFrontend/EDG"},
#             {"editType":"edit",
#              "file":"tests/CompileTests/Cxx_tests/Makefile.am"},
#             {"editType":"add",
#              "file":"tests/CompileTests/Cxx_tests/test2011_151.C"}]},
#         {"author":
#             {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Kamal%20Sharma",
#              "fullName":"Kamal Sharma"},
#          "comment":"Added stdlib.h for new version of gcc >= 4.3.2.\n",
#          "date":"2011-11-08 14:40:45 -0600",
#          "id":"0d0b3063b3446f50291f07a3798f8d1568cf28ca",
#          "msg":"Added stdlib.h for new version of gcc >= 4.3.2.",
#          "paths":[
#             {"editType":"edit",
#              "file":"projects/DataFaultTolerance/src/faultToleranceArrayLibUtility.C"},
#             {"editType":"edit",
#              "file":"projects/DataFaultTolerance/src/arrayBase.h"},
#             {"editType":"edit",
#              "file":"projects/DataFaultTolerance/src/pragmaHandling.C"}]}],
#      "kind":null},
#   "culprits":[
#     {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Justin%20Too",
#      "fullName":"Justin Too"},
#     {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Dan%20Quinlan",
#      "fullName":"Dan Quinlan"},
#     {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Kamal%20Sharma",
#      "fullName":"Kamal Sharma"}]}


