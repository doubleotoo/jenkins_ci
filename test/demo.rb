require 'logger'
require 'active_record'

require 'jenkins_ci'

schema = CI::Jenkins::DB::Schema.new(adapter='sqlite3', database='tmp-demo.sqlite3', force=true)
jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
#v = CI::Jenkins::View.create('Integration', jenkins, exclude_projects=['C0-Poll', 'C0-Queue'])
p = CI::Jenkins::DB::Project.find_by_project_name('C1-ROSE-from-scratch-linux-full')
b = CI::Jenkins::Build.create(566, p, jenkins)
#puts CI::Jenkins::DB::Build.distinct_branches
#puts CI::Jenkins::DB::Build.distinct_sha1s
#CI::Jenkins::DB::Build.sha1s_by_branch.each do |branch, sha1s|
#  puts branch
#  sha1s.each do |sha1, projects|
#    puts "`--> #{sha1}"
#    projects.each do |project, builds|
#      puts "   `--> #{project}"
#      builds.each do |build|
#        puts "       `--> #{build.number}"
#      end
#    end
#  end
#end

#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
#v = CI::Jenkins::View.create('All', jenkins)

