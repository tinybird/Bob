require 'rubygems'
require 'grit'
require 'pathname'

class Project
  attr_reader :name, :path
  attr_accessor :email_addresses, :build_command, :build_options, :url, :ignored_file_extensions

  def self.all
    configs = Dir.glob(File.join(ENV['HOME'], '.bob/projects/*/config.rb'));
    configs.map { |path| load_project_config(path) }
  end

  def self.load_project_config(config_path)
    @project_to_configure = new(Pathname.new(config_path).parent) 
    load config_path
    project = @project_to_configure
    @project_to_configure = nil
    return project
  end

  def self.configure
    raise 'No project is currently being created' unless @project_to_configure
    yield @project_to_configure
  end

  def initialize(path)
    @path = path
    @name = @path.basename.to_s
    @email_addresses = []
    @build_command = nil
    @build_options = {}
    @ignored_file_extensions = []
  end

  def last_build_status
    begin
      last_commit, previous_status = File.read(File.join(self.path, "build-status")).split(/\n/)
    rescue => e
      # Let's assume this is the first build if the status file can't be read.
      BobLogger.info "Couldn't read previous build status: #{e}"
      previous_status = "fresh"
      last_commit = nil
    end
    [last_commit, previous_status]
  end

  def write_build_status(commit, status)
    File.open(File.join(self.path, "build-status"), 'w') { |f| f << "#{commit}\n#{status}" }
  end

  def get_git_repository
    # Try to create a Grit::Repo for path

    path = File.join(self.path, "work")
    if File.exists?(self.path) && File.directory?(path)
      system("cd #{File.join(self.path, 'work')} && git pull > /dev/null")
    else
      system("cd #{self.path} && git clone #{self.url} work > /dev/null")
    end

    begin
      repo = Grit::Repo.new(File.join(self.path, 'work'))
      BobLogger.info "Repository with #{repo.commit_count} commits created for #{self.name}"
    rescue => e
      BobLogger.info("Failed to create repository for #{self.name} due to #{e}")
      return nil
    end
    repo
  end

  def build(new_commits, previous_status)
    BobLogger.info "Building: #{self.name}"
    build = Build.new(self, new_commits)
    build.build
    
    if Settings.email_when_no_status_change or previous_status != build.status
      BobLogger.info "Sending build report"
      if Settings.sender
        Mailer.send(:deliver_build_report, build, self.email_addresses,
                    Settings.sender, "#{self.name} #{build.status}, #{new_commits[0].id_abbrev}", "")
      end
    end
    write_build_status(new_commits.last, build.status.to_s)
    BobLogger.info "Build finished for #{self.name} with status '#{build.status.to_s}'"
  end

  def to_param
    @name
  end
end
