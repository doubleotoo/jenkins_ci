# tagalog.rb
#
# Base Jenkins instance.

#  Usage:
#
#    Tagalog::log(message, tag);
#
#    +message+ is something stringable, or an array of stringable things.
#    +tag+     is either a tag symbol or an array of tag symbols.

# ==== Configuration
#
# * +:kill_switch+ - If true, turns off ALL logging.
# * +:log_file_path+ -
# * +:date_format+ -
# * +:message_format+ -
# * +:tags+ -
#
class Tagalog
  class << self; attr_accessor :config, :writer end

  #-----------------------------------------------------------------------------
  #  Configuration
  #-----------------------------------------------------------------------------

  # Log configuration - edit inline or extend/override
  @config = {
    # set this to true if you want ALL logging turned off:
    :kill_switch => false,

    :log_file_path => "/tmp/log/tagalog.log",

    :date_format => "%Y-%m-%d %H:%M:%S",

    # $C = caller
    # $D = date
    # $L = logger
    # $M = message
    # $T = tag
    :message_format => "$D [$T] $L < $C - $M", # ~log4j

    # turn logging on and off here for various tags:
    :tags =>  {
      :untagged => true, # this one is special (default)
    }
  }
  
  @writer = nil

  #-----------------------------------------------------------------------------
  #  Methods
  #-----------------------------------------------------------------------------

  # Logs a tagged message.
  #
  # ==== Attributes
  #
  # * +message+ - Something that can be cast as a string.
  # * +tag+ - Tag symbol or an array of tag symbols.
  #
  # Returns a boolean, indicating whether or not logging occurred.
  #
  def self.log(message, tags=:untagged)
    logging_method = caller[0][/`.*'/][1..-2]

    return false if @config[:kill_switch]

    if tags.is_a?(Symbol)
      tags = [tags]
    end

    tags = tags.select { |tag| self.is_tag_enabled? tag }
    return false if tags.empty?
    
    logged_message = false
    tags.each do |tag|
      this_message = @config[:message_format].to_s
      this_message = this_message.gsub(/\$(C|D|L|M|T)/) do |match|
        string = ''
        case match
        when '$C'
          string = logging_method
        when '$D'
          string = Time.now.strftime @config[:date_format]
        when '$L'
          string = self.to_s
        when '$M'
          string = message
        when '$T'
          string = tag
        end
        string
      end #-end this_message.gsub

      self.write_message this_message
      logged_message = true
    end #-end tags.each

    return logged_message
  end #-end self.log (message, tag)

  # Performs low-level logging operations.
  def self.write_message(message)
    if @writer
      return @writer.call(message) # TODO:
    else
      path = @config[:log_file_path]
      open(path, 'a') { |f| f.puts message }
    end
  end #-end self.write_message (message)

  # This takes a Method as its parameters, which it will call upon writing
  # rather than the standard write_method actions.  Good for distributed
  # platforms like Heroku
  #
  # Example:
  #
  #   class TagalogWriters
  #      def self.heroku_writer(message)
  #        puts message
  #      end
  #    end
  #   
  #   configure :production do
  #     Tagalog.set_writer(TagalogWriters.method(:heroku_writer))
  #   end
  #
  def self.set_writer(closure)
    if closure.is_a? Method
      @writer = closure 
    else
      raise TagalogException, "writer must be a Method"
    end
  end

  # Returns true if +tag+ is a valid Tagalog tag (configurable).
  def self.is_tag_defined?(tag)
    @config[:tags].has_key? tag
  end

  # Returns true if Tagalog has been configured to log messages with
  # +tag+ (configurable).
  def self.is_tag_enabled?(tag)
    if self.is_tag_defined? tag
      return @config[:tags][tag]
    else
      raise TagalogException, "undefined tag '#{tag}'"
    end
  end

  # Returns an Array of the enabled tags (configurable).
  def self.get_loggable_tags
    @config[:tags].select { |tag| self.is_tag_enabled? tag }
  end
end #-end class Tagalog

class TagalogException < Exception
end


# <license stuff>
# 
# tagalog is licensed under The MIT License
# 
# Copyright (c) 2010 Kyle Wild (dorkitude) - available at http://github.com/dorkitude/tagalog
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
# 
# </license stuff>

