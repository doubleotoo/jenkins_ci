Gem::Specification.new do |s|
  s.name        = 'jenkins_ci'
  s.version     = '0.0.0'
  s.date        = '2011-03-14'
  s.summary     = "Jenkins remote API"
  s.description = "A gem to utilize the Jenkins CI remote API"
  s.authors     = ["Justin Too"]
  s.email       = 'too1@llnl.gov'
  s.files       = ["lib/jenkins_ci.rb"] +
                  Dir['lib/jenkins_ci/api/*.rb']
  s.homepage    =
    'http://rubygems.org/gems/jenkins_ci'
end

