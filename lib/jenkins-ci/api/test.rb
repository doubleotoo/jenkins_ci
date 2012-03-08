
load 'jenkins.rb'
load 'json_resource.rb'
load 'project.rb'

#jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')

project = CI::Jenkins::Project.create('a00-commit', jenkins, false)
puts project.j_downstreamProjects

project = CI::Jenkins::Project.create('zz-Commit', jenkins, false)
puts project.j_upstreamProjects

