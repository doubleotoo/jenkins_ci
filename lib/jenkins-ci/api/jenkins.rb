# jenkins.rb
#
# Base Jenkins instance.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------
require 'rubygems'
require 'app_config'

require 'open4'
require 'json'
require 'uri'

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins

class JenkinsError < Exception
end

class Jenkins
  attr_accessor :user,
                :password,
                :base_url,
                :timeout

  # ==== Arguments
  #  * +user+ is a privileged Jenkins user.
  #  * +password+ is the +user+'s password.
  #  * +base_url+ is the base URL of the Jenkins server.
  #  * +timeout+ is the number of seconds to wait for the Jenkins server to
  #    respond before timing out a query.
  #
  def initialize(user, password, base_url, timeout=5)
    @user     = user
    @password = password
    @base_url = base_url
    @timeout  = timeout
  end #-end initialize()

  #-----------------------------------------------------------------------------
  #  Private:
  #-----------------------------------------------------------------------------

  # ==== Arguments
  #
  # * +url+ is a relative query URL.
  #
  #   The final query is: base_url + url.
  #
  # Returns the obfuscated query.
  #
  def submit_query(url)
    query="curl --fail --silent --show-error --globoff --user #{@user}:#{@password} #{url}"
    obfuscated_query=query.sub(@password, "xxx")

    query_stdout = nil
    curl_error = nil
    status = Open4::popen4(query) do |pid, stdin, query_stdout, stderr|
      begin
        status = Timeout::timeout(@timeout) {
            curl_error = stderr.read
            if not curl_error.empty?
              raise JenkinsError,
                "'#{curl_error.strip}' after issuing query '#{obfuscated_query}'"
            end
        }
      rescue Timeout::Error
        stderr.close
      end
      
      yield(obfuscated_query, query_stdout) if block_given?
    end #-end Open4::popen4 (query)

    if status.nil?
    raise JenkinsError, "popen4 returned status #{status}"
    end

    return obfuscated_query
  end #-end submit_query (url)

  # ==== Arguments
  #
  # * +url+ is a relative query URL (will be URI escaped).
  #
  # * +parameters+ is an array of http parameters
  #   TODO: validation, create class HttpParameter
  #
  #   e.g. [depth=1, tree=jobs[name]]
  #   =>   depth=1&tree=jobs[name]
  #
  #   The final query is: base_url + url.
  #
  # Returns the parsed JSON from +url+.
  #
  #--
  # Pretty print JSON: http://www.cerny-online.com/cerny.js/demos/json-pretty-printing
  #--
  #
  def get_json(url, parameters=[])
    json=nil
    encoded_url = URI.escape(url)
    query=@base_url + encoded_url + '/api/json?' + parameters.join('&')
    submit_query(query) { |obfuscated_query, query_stdout|
      begin
        json = query_stdout.read
        json = JSON.parse(json)
      rescue JSON::ParserError => parser_error
        raise JenkinsError,
          "malformed JSON '#{json}' received from query " +
          "'#{obfuscated_query}' (#{parser_error})"
      end
    }
    json
  end
end #-end class Jenkins
end #-end module Jenkins
end #-end module CI

