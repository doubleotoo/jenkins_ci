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
class JsonResource
  class << self
    protected :new, :allocate
  end
  attr_reader :path,  # resource path, e.g. '/job/C0-Start'
              :json,
              :jenkins,
              :parameters

  def initialize(path, jenkins, parameters=[])
    raise "NilError" if path.nil? or jenkins.nil?

    @path       = path
    @jenkins    = jenkins
    @parameters = parameters
    @json       = nil

    sync()
  end

  # ==== Arguments
  #
  # Returns this Resource's JSON string.
  #
  def get_json
    return @jenkins.get_json(@path, @parameters)
  end

  # Setup this Resource with its corresponding Jenkins JSON.
  def sync
    raise NotImplementedError
  end

  # +*args+ is an array of String objects.
  #
  #     We could call "args.join" first to convert "*args"
  #     into a String, but then we wouldn't be able to
  #     sort properly.
  #
  #     For example:
  #
  #       Foo.generate_cache_key('Bob', 13.to_s, 'Jill')
  #
  #       args.join => 'Bob13Jill'
  #           .sort => '13BJbillo'
  #
  #       -versus-
  #
  #       args.sort => [13, 'Bob', 'Jill]
  #           .join => '13BobJill'
  #
  def self.generate_cache_key(*args)
    # TODO: add optional validation? could be expensive!
    args.sort.join.hash
  end

#-------------------------------------------------------------------------------
#  Private
#-------------------------------------------------------------------------------
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

