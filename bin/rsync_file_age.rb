#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'rsync_utils')

include CommandHelper

@details = <<EOD
Description:
  Check the age of files in an rsync module path and return nagios
  check states if results are outside the specified ranges. Time 
  ranges should be specified in seconds. 

Example:
  Check for files on somehost in the somedir module and anotherdir/ 
  sub-directory. Return a warning state if files are outside the range 
  of 0-10 seconds old. Return a critical state if files are outside the 
  range of 10-20 seconds old.

  $ rsync_file_age.rb -H somehost -P somedir/anotherdir/ -w "0:10" -c "10:20" 
 
EOD

@options = {}
# Default
@opts = OptionParser.new

@opts.on(
  "-H", "--hostname HOSTNAME", "Hostname"
) { |value| @options[:hostname] = value }

@opts.on(
  "-P", "--path PATH", "Path to Query"
) { |value| @options[:path] = value }

@opts.on(
  "-w", "--warning WARNING", "Return warning if outside this range"
) { |value| @options[:warning] = value }

@opts.on(
  "-c", "--critical CRITICAL", "Return critical if outside this range"
) { |value| @options[:critical]= value }

@opts.on(
  '-r', "--recursive", "Search recursively"
) { |value| @options[:recursive] = value }

@opts.on(
  "-d", "--drift DRIFT", "Time drift in seconds"
) { |value| @options[:drift] = value }

@opts.on(
  "-v", "--verbose", "Print out all files in path"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }



def get_files
  rsync = RsyncUtils.new
  rsync.show(@options[:hostname],@options[:path],@options[:recursive])
end

def check_files
  nagios = nagios_check_age(get_files)
  nagios.message = "#{nagios.result} files #{nagios.threshold} seconds old"
  nagios
end

def nagios_check_age(list)
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  files = []
  list.results.each do |file|
    if file.is_file?
      diff = ((::Time.now - file.time) - @options[:drift].to_i).to_i
      files << check.compare(diff)
    end
  end
  crit = files.select {|r| r.kind_of? NagiosResult::Critical }.length
  warn = files.select {|r| r.kind_of? NagiosResult::Warning }.length
  return NagiosResult::Critical.new(check.critical[:output],crit) if crit > 0
  return NagiosResult::Warning.new(check.warning[:output],warn) if warn > 0
  return NagiosResult::Ok.new(check.ok[:output],0)
end

begin
  @opts.parse!
rescue StandardError => e
  print_help("Error: #{e.message}") unless e.message == "exit"
end

unless @options[:hostname] && @options[:path]
  print_help("Missing Arguments: hostname and path are required.")
end

begin
  if @options[:verbose]
    puts get_files.stdout
  else
    print_results(check_files)
  end
rescue StandardError => e
  print_exception(e)
end

