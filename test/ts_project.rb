$: << File.dirname(__FILE__)
Dir[File.dirname(__FILE__) + '/' + "#{File.basename(__FILE__, File.extname(__FILE__))}" + '/*.rb'].each { |file| require file }

