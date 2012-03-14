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

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
#
# Create View using named constructor +View.create+.
#
class View  < JsonResource
  attr_reader :name
  class << self; attr_accessor :cache end
  @cache = {} # TODO: remove, should be INHERITED from JsonResource < CacheableObject

  def self.create(name, jenkins, lazy_load=true)
    if name.nil? or jenkins.nil?
      raise "View::NilError: name=#{name}, jenkins=#{jenkins}"
    end

    key = generate_cache_key(name)
    @cache[key] ||= new(name, jenkins, lazy_load)
  end

  # ==== Arguments
  #  * +name+ is the name of this Jenkins view.
  #  * +jenkins+ is the Jenkins server instance.
  #  * +lazy_load+ indicates whether we should load only
  #    when required.
  #
  def initialize(name, jenkins, lazy_load=true)
    @name = name
    super("/view/#{name}", jenkins, lazy_load)
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
    :j_description            =>  'description',            # html string
    :j_jobs                   =>  'jobs',                   # array [{name, url, color}, ..]
    :j_name                   =>  'name',                   # string
    :j_property               =>  'property',               # array (?)
    :j_url                    =>  'url',                    # string
  }

end #-end class View
end #-end module Jenkins
end #-end module CI

