require 'jenkins_ci'

puts "Running test file..."

$verbose = true

def integration_jobs(jenkins)
  builds_by_branch = {}
  view = CI::Jenkins::View.create('Integration', jenkins, false)
  view.j_jobs.each do |job|
    next if ['C0-Poll', 'C0-Queue'].include?(job.name)

    puts "#{job.name} has #{job.j_builds.size} builds:"
    job.j_builds.each do |build|
      summary = build.summary
      next if summary[:j_description].nil? or summary[:j_description].split[1].nil?
      sha1   = summary[:j_description].split[0]
      branch = summary[:j_description].split[1]

      builds_by_branch[branch] ||= {}
      builds_by_branch[branch][sha1] ||= {}
      builds_by_branch[branch][sha1][job.name] ||= {:job => job, :builds => []}
      builds_by_branch[branch][sha1][job.name][:builds].push(build)
    end
  end

  builds_by_branch.each do |branch, sha1s|
    puts "#{branch} tested on #{sha1s.size} sha1s"
    sha1s.each do |sha1, job_names|
      puts "  #{sha1} tested in #{job_names.size} jobs"
      job_names.each do |job_name, job_and_builds|
        builds = job_and_builds[:builds]
        puts "    #{job_name} has #{builds.size} builds"
        builds.each do |build|
          summary = build.summary
          if summary[:j_building] == true
            puts "    `---#{summary[:j_number]} BUILDING "
          else
            puts "    `---#{summary[:j_number]} #{summary[:j_result]}"
          end
        end
      end
    end
  end
end

def get_all_projects
  CI::Jenkins::Project.get_all(jenkins).each do |project|
    puts project.j_name
  end
end

jenkins = CI::Jenkins::Jenkins.new('hudson-rose', 'HRoseP4ss', 'http://hudson-rose-30:8080/')

integration_jobs(jenkins)

