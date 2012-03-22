# queue_item.rb
#
# Base Jenkins queueItem instance.
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
# Create queueItem using named constructor +QueueItem.create+.
#
class QueueItem
  attr_reader :blocked,
              :buildable,
              :params,
              :stuck,
              :task,
              :why,
              :buildableStartMilliseconds

  # ==== Arguments
  #  * +foo+ bar description.
  #
  def initialize(blocked, buildable, params, stuck, task, why, buildableStartMilliseconds)
    @j_blocked    = blocked
    @j_buildable  = buildable
    @j_params     = params
    @j_stuck      = stuck
    @j_task       = task
    @j_why        = why
    @j_buildableStartMilliseconds = buildableStartMilliseconds
  end

  #-----------------------------------------------------------------------------
  #  API
  #-----------------------------------------------------------------------------

  def to_s
    {
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

#  DETAIL = {
#   Internal symbol               Jenkins symbol            Description
#   ===============               ==============            ===========
#    :j_blocked                =>  'blocked',                # boolean
#    :j_buildable              =>  'buildable',              # boolean
#    :j_params                 =>  'params',                 # string
#    :j_stuck                  =>  'stuck',                  # boolean
#    :j_task                   =>  'task',                   # {name, url}
#    :j_why                    =>  'why',                    # string
#    :j_buildableStartMilliseconds =>  'buildableStartMilliseconds' # integer
#  }

end #-end class QueueItem
end #-end module Jenkins
end #-end module CI

