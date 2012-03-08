$: << File.dirname(__FILE__)
Dir[File.dirname(__FILE__) + '/' + 'ts_*.rb'].each { |file| require file }

