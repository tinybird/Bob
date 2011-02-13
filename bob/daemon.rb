# Load site configuration, for email settings and other global configuration.
site_config = File.join(ENV['HOME'], '.bob', 'site_config.rb')
load site_config if File.exists?(site_config)

BobLogger.info "\n========================================================"
BobLogger.info "Builder daemon started at #{Time.now}"

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
        BobLogger.info "Last built commit: #{last_commit}\nLatest available commit: #{repo.commits.first}"
        new_commits = repo.commits_between(last_commit, repo.commits.first)
        if (new_commits.length > 0)
          should_build = true
          BobLogger.info "#{new_commits.length} new commits:"
          new_commits.each { |commit| BobLogger.info "  #{commit.id_abbrev}"}
        end
      end

      project.build(new_commits, previous_status) if should_build == true
      sleep 1
    end
  end

  BobLogger.info "Builder #{Process.pid} still alive at #{Time.now}, sleeping..."
  sleep Settings.sleep_duration
end

BobLogger.info "Builder daemon stopped at #{Time.now}"
