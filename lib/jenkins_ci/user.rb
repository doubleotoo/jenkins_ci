# user.rb
#
# Base Jenkins User instance.
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

require 'uri'

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
class User < JsonResource

  attr_reader :full_name

  @cache = {} # TODO: remove, should be INHERITED from JsonResource < CacheableObject

  def self.create(full_name, jenkins, lazy_load=true)
    key = generate_cache_key(full_name)

    @cache[key] ||= new(full_name, jenkins, lazy_load)
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
  def initialize(full_name, jenkins, lazy_load=true)
    @full_name = full_name
    #super("/user/#{URI.escape(full_name)}", jenkins, lazy_load)
    super("/user/#{full_name}", jenkins, lazy_load)
  end

  def <=>(o)
    return self.full_name <=> o.full_name
  end

  #-----------------------------------------------------------------------------
  #  API
  #-----------------------------------------------------------------------------

#  DETAIL = {
#   Internal symbol           Jenkins symbol            Description
#   ===============           ==============            ===========
#    :j_absoluteUrl      =>    'absoluteUrl',            # string
#    :j_description      =>    'description',            # string
#    :j_fullName         =>    'fullName',               # string
#    :j_id               =>    'id',                     # string
#    :j_property         =>    'property'                # array of {}
#      # { "address" => "email" }
#  }

end #-end class Build
end #-end module Jenkins
end #-end module CI

# Example extract of JSON
# {"absoluteUrl":"http://hudson-rose-30.llnl.gov:8080/user/Justin%20Too",
#  "description": null,
#  "fullName": "Justin Too",
#  "id": "Justin Too",
#  "property":[
#     {},
#     {"address":"too1@llnl.gov"}]}

