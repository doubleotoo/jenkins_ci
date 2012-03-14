load 'jenkins.rb'
load 'json_resource.rb'
#load 'project.rb'
load 'view.rb'

#$verbose = true

jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')

#CI::Jenkins::Project.get_all(jenkins, lazy_load=false).each do |project|
#  puts project.j_name
#end

#CI::Jenkins::View.create('Integration', jenkins, false)
CI::Jenkins::Project.create('R1-ROSE_with_glibcxx_debug', jenkins, false)

[
  'C0-Start',
  'C1-ROSE-from-scratch-linux',
  'C1-ROSE-from-scratch-linux-full',
  'C1-ROSE-from-scratch-osx',
  'C1-ROSE-from-scratch-osx-full',
  'C2-ROSE-language-matrix-linux',
  'C2-ROSE-language-matrix-osx',
  'C3-ROSE-BOOST-matrix',
  'C4-ROSE-make-docs',
  'C5-ROSE-cmake-build',
  'C6-ROSE-distcheck',
  'C7-ROSE_with_glibcxx_debug'
].each do |jobname|
  CI::Jenkins::Project.create(jobname, jenkins, false)
  
end

