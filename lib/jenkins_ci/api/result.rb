# result.rb
#
# Base Result instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
$: << File.dirname( __FILE__)

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
class Result
  attr_reader :status
  
  SUCCESS = 'SUCCESS'
  FAILURE = 'FAILURE'
  ABORTED = 'ABORTED'

  VALID_RESULTS = [
    SUCCESS,
    FAILURE,
    ABORTED
  ]

  def initialize(status)
    if not VALID_RESULTS.include?(status)
      raise "Invalid Result::status=#{status}; expected #{VALID_RESULTS}"
    else
      @status = status
    end
  end

  def <=>(o)
    return self.status <=> o.status
  end

  #-----------------------------------------------------------------------------
  #  API
  #-----------------------------------------------------------------------------

  def is_success?
    SUCCESS == @status
  end

  def is_failure?
    FAILURE == @status
  end

  def is_aborted?
    ABORTED == @status
  end

  def to_s
    @status
  end

end #-end class Result
end #-end module Jenkins
end #-end module CI

