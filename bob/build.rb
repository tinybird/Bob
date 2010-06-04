require 'platform'
require 'command_line'

class Build
  attr_reader :project, :revisions, :status, :log, :summary

  def initialize(project, revisions)
     @project = project
     @revisions = revisions
     BobLogger.debug "Creating build for project: #{@project.name}"
  end

  def build
    command = @project.build_command
    if not command or command.empty?
      root = File.expand_path("#{File.dirname(__FILE__)}/..")
      command = File.join(root, 'script', 'xcodebuild-helper.rb')
    end
      
    @status = "failed"
    @summary = []
    @log = []

    @project.build_options.each do |key, value|
      ENV["BOB_#{key.to_s.upcase}"] = value
    end

    full_log = []
    failed_message = nil
    begin
      Dir.chdir(File.join(@project.path, "work")) do
        CommandLine::execute([command]) do |io|
          full_log = io.readlines
        end
        @status = "succeeded"
      end

    rescue => e
      # Only log the error if we don't have any output yet, since it usually indicates an
      # issue with the build script, and for normal failures we don't want the extra spam.
      failed_message = "Build script failed:\n#{e.message}"
    end

    # Reset the settings that are passed as environment variables.
    @project.build_options.each do |key, value|
      ENV["BOB_#{key.to_s.upcase}"] = nil
    end

    # Split the full log into summary and full log parts.
    log_mode_full = true
    log_mode_summary = false
    full_log.each do |line|
      if line.match(/# BOB LOG FULL/)
        log_mode_full = true
        log_mode_summary = false
      elsif line.match(/# BOB LOG SUMMARY/)
        log_mode_summary = true
        log_mode_full = false
      elsif line.match(/# BOB LOG ALL/)
        log_mode_summary = true
        log_mode_full = true
      else
        if log_mode_full
          @log << line
        end
        if log_mode_summary
          @summary << line
        end
      end
    end

    if failed_message
      if @log.empty?
        @log = failed_message
      end
      if @summary.empty?
        @summary = failed_message
      end
    end

  end

end
