Dir[File.dirname(__FILE__) + '/jenkins_ci/api/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/jenkins_ci/models/*.rb'].each { |file| require file }

module CI
module Jenkins
  $logger=Logger.new(STDERR)
end #-module CI
end #-module Jenkins

