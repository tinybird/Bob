# Load site configuration, for email settings and other global configuration.
site_config = File.join(ENV['HOME'], '.bob', 'site_config.rb')
load site_config if File.exists?(site_config)

BobLogger.get.level = Logger::INFO

BobLogger.info "\n========================================================"
BobLogger.info "#{Time.now.strftime('%Y-%m-%d %H:%M')} - Builder started, PID: #{Process.pid}."

projects = Project.all
BobLogger.info "Projects:"
projects.each { |p| BobLogger.info "  #{p.name}" }

while(true) do
	BobLogger.info ""
  projects.each do |project|
    if project.enabled
      
      load site_config if File.exists?(site_config)
      
      BobLogger.info "Updating: #{project.name}"

      should_build = false

      repo = project.get_git_repository
      last_commit, previous_status = project.last_build_status

      if last_commit == nil
        BobLogger.info "New project that hasn't been built before: #{project.name}"
        should_build = true
        new_commits = repo.commits('master', 1)
      else
        BobLogger.debug "Last built commit: #{last_commit[0..6]}, newest: #{repo.commits.first.id_abbrev}"
        new_commits = repo.commits_between(last_commit, repo.commits.first)
        if (not new_commits.empty?)
          should_build = true
          BobLogger.info "#{new_commits.length} new commits:"
          new_commits.each { |commit| BobLogger.info "  #{commit.id_abbrev}"}
        end
      end

      project.build(new_commits, previous_status) if should_build == true
      sleep 1
    end
  end

  BobLogger.info "#{Time.now.strftime('%Y-%m-%d %H:%M')} - Builder alive, PID: #{Process.pid}. Sleeping for #{Settings.sleep_duration} seconds."
  sleep Settings.sleep_duration
end

BobLogger.info "Builder daemon stopped at #{Time.now}"
