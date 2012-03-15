# cached_object.rb
#
# Cached Ruby object.
#
# Author::    Justin A. Too (mailto:too1@llnl.gov)
# Copyright:: Copyright (c) 2011 LLNL
# License::   Distributes under the same terms as ROSE.
#

#-------------------------------------------------------------------------------
#  Dependencies
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#  Jenkins
#-------------------------------------------------------------------------------

module CI
module Jenkins
class CacheableObject
  class << self
    private :new, :allocate
    attr_reader :cache
  end
  @cache = {}

  # Example:
  # def self.create(name, age)
  #   key = generate_cache_key(name, age)
  #   @cache[key] ||= new(name, age)
  # end

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
end #-end class CacheableObject
end #-end module Jenkins
end #-end module CI

