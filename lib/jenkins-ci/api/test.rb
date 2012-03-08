load 'jenkins.rb'
load 'json_resource.rb'
load 'project.rb'

#jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')

project = CI::Jenkins::Project.create('a00-commit', jenkins, false)
#puts project.j_downstreamProjects

project = CI::Jenkins::Project.create('zz-Commit', jenkins, false)
#puts project.j_upstreamProjects
project.print_api
puts project.j_displayName
#puts project.j_lastSuccessfulBuild.to_s
#puts project.j_lastSuccessfulBuild.j_actions.to_s
puts project.j_nextBuildNumber
puts project.j_lastBuild
puts project.j_lastBuild.to_s
puts project.j_lastBuild.print_api
puts project.j_lastBuild.j_building
project.j_builds.each do |build|
  puts "#{build.j_number} #{build.j_result}"
end

project = CI::Jenkins::Project.create('Test', jenkins, false)
puts "actions=#{project.j_actions}"
puts "queue=#{project.j_inQueue}"
puts "queueItem=#{project.j_queueItem.to_s}"
puts "buildable=#{project.j_buildable}"
puts "scm=#{project.j_scm}"
puts "lastBuild=#{project.j_lastBuild.to_s}"
puts "next=#{project.j_nextBuildNumber}"


