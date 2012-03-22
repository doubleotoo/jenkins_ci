require 'logger'
require 'active_record'

require 'jenkins_ci'

schema = CI::Jenkins::DB::Schema.new(adapter='sqlite3', database='tmp-demo.sqlite3', force=true)
jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')
v = CI::Jenkins::View.create('Integration', jenkins, exclude_projects=['C0-Poll', 'C0-Queue'])
puts CI::Jenkins::DB::Build.distinct_branches
puts CI::Jenkins::DB::Build.distinct_sha1s

#jenkins = CI::Jenkins::Jenkins.new('too1', 'Jatusa1@', 'http://localhost:8080/')
#v = CI::Jenkins::View.create('All', jenkins)

