#!/usr/bin/env ruby

require 'fileutils'
require 'tempfile'

configuration = ENV['BOB_CONFIGURATION']
target = ENV['BOB_TARGET']
sen_test_target = ENV['BOB_SEN_TEST_TARGET']
bacon_test_target = ENV['BOB_BACON_TEST_TARGET']
release_target = ENV['BOB_RELEASE_TARGET']

def get_arguments(configuration, target)
  args = ""
  if configuration and configuration != ""
    args << "-configuration \"#{configuration}\" "
  end
  if target and target != ""
    args << "-target \"#{target}\" "
  end
  sdk_name = ENV['BOB_SDK_NAME']
  if sdk_name and sdk_name != ""
    args << "-sdk \"#{sdk_name}\" "
  end
  args    
end  

def print_issues(issues)
  issues.each do |issue|
    puts "  #{issue}"
  end
end

def print_log(issues, from_line)
  puts
  puts "The full log from the first issue found:"
  puts
  puts issues[from_line..-1]
end

# Returns (succeeded, log, warnings, errors, tests, first_issue_line).
def run_tool(tool, command, configuration, target)
  log = Tempfile.new("boblog")
  succeeded = system("#{tool} #{get_arguments(configuration, target)} #{command} > #{log.path} 2>&1")

  i = 0
  first_issue_line = -1
  errors = []
  warnings = []
  tests = []

  build_path = FileUtils.pwd
  
  lines = log.readlines
  lines.each do |line|
    warning = line.match(/warning: /)
    error = line.match(/error: /)
    suite = line.match(/Test Suite \'/)
    test = line.match(/Test Case \'/)

    # Make any absolute build dir paths relative to the working dir.
    trimmed_line = line.sub(/#{build_path}\//, "")

    if error
      errors << trimmed_line
    elsif warning
      warnings << trimmed_line
    elsif suite
      # Strip out some unnecessary information.
      trimmed_line = trimmed_line.sub(/ started at.*/, "")
      
      # Trim out some builtin SenTesting suites and other unwanted lines.
      if not (line.match(/SenTestingKit\.framework/) or
              line.match(/SenInterfaceTestCase/) or
              line.match(/Test Suite \'All tests\'/) or
              line.match(/\.octest\(Tests\)/) or
              line.match(/\' finished at /))
        tests << trimmed_line
      end
    elsif test
      # Strip out some unnecessary information.
      trimmed_line = trimmed_line.sub(/ \(.*\)\./, "")

      # Trim out some other unwanted overly verbose lines.
      if not (line.match(/\' started\./))
        tests << "  #{trimmed_line}"
      end
    end

    if error or warning and first_issue_line == -1
      first_issue_line = i
    end

    i += 1
  end

  return succeeded, lines, warnings, errors, tests, first_issue_line
end

def run_bacon_test(configuration, target)
  log = Tempfile.new("boblog")
  succeeded = system("xcodebuild #{get_arguments(configuration, target)} build > #{log.path} 2>&1")

  tests = []

  build_path = FileUtils.pwd
  
  lines = log.readlines
  lines.each do |line|
    failed = line.match(/\[FAILED\]/)
    should = line.match(/^- should/)

    if failed
      tests << "<span class='failed'>" + line.sub(/\n/, "") + "</span>\n"
    elsif line.strip == "" and tests.last and tests.last.strip == ""
		  # Strip out double newlines.
    elsif not (line.match(/===/) or
               line.match(/Check dependencies/) or
               line.match(/^   /) or
               line.match(/PhaseScriptExecution/) or
               line.match(/BUILD SUCCEEDED/))
      tests << line
    end
  end

  return succeeded, [], [], [], tests, 0
end

def set_log_mode(mode)
  if mode == :summary
    puts '# BOB LOG SUMMARY'
  elsif mode == :full
    puts '# BOB LOG FULL'
  elsif mode == :all
    puts '# BOB LOG ALL'
  end
end

def print_ok
  puts "<span class='succeeded'>OK</span>"
end

def print_failed
  puts "<span class='failed'>failed:</span>"
end

def run_clean(configuration, target)
  succeeded, log, warnings, errors, tests, first_issue_line = run_tool("xcodebuild", "clean", configuration, target)

  set_log_mode(:all)
  print "Cleaning '#{configuration}'... "
  if succeeded
    print_ok
  else
    print_failed
    set_log_mode(:full)
    print_log log, first_issue_line
    Process.exit 1
  end
end

def run_build(configuration, target)
  succeeded, log, warnings, errors, tests, first_issue_line = run_tool("xcodebuild", "build", configuration, target)

  set_log_mode(:all)
  print "Building '#{configuration}'... "
  if succeeded
    print_ok
  else
    print_failed
		print "\n"
  end
  print_issues errors + warnings

  if not succeeded
    set_log_mode(:full)
    print_log log, first_issue_line
    Process.exit 1
  end
end

def run_test(configuration, target, bacon=false)
  if bacon
    succeeded, log, warnings, errors, tests, first_issue_line = run_bacon_test(configuration, target)
  else
    succeeded, log, warnings, errors, tests, first_issue_line = run_tool("xcodebuild", "build", configuration, target)
  end

  set_log_mode(:summary)
  print "Running tests... "
  if succeeded
    print_ok
  else
    print_failed
    print_issues tests
  end
  
  # Always print the full info in the full log.
  set_log_mode(:full)
  print "Running tests...     "
  if succeeded
    print_ok
  else
    print_failed
  end

  print_issues tests

  Process.exit 1 unless succeeded
end

run_clean configuration, target
run_build configuration, target
if bacon_test_target
  run_test configuration, bacon_test_target, true
end
if sen_test_target
  run_test configuration, sen_test_target, false
end
if release_target
	run_clean "Release", release_target  
	run_build "Release", release_target
end
