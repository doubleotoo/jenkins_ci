Gem::Specification.new do |s|
  s.name        = 'jenkins_ci'
  s.version     = '0.0.0'
  s.date        = '2011-03-14'
  s.summary     = 'Jenkins remote API'
  s.description = 'A gem to utilize the Jenkins CI remote API'
  s.authors     = ['Justin Too']
  s.email       = 'doubleotoo@gmail.com'
  s.files       = ["lib/jenkins_ci.rb"] +
                  Dir['lib/jenkins_ci/api/*.rb'] +
                  Dir['lib/jenkins_ci/models/*.rb']
  s.homepage    = 'http://rubygems.org/gems/jenkins_ci'

  s.require_paths = ['lib']

  s.add_runtime_dependency('json', ['>= 1.6.0'])
  s.add_runtime_dependency('open4', ['>= 1.2.0'])
  s.add_runtime_dependency('activerecord', ['>= 3.1.1'])
end

