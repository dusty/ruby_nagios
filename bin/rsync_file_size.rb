#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'rsync_utils')

include CommandHelper

@details = <<EOD
Description:
  Check the size of files in an rsync module path and return nagios
  check states if any files are outside the specified ranges. 

Example:
  Check for files on somehost in the somedir module and anotherdir/ 
  sub-directory. Return a warning state if any files are outside the size 
  of 0-5 MB. 

  $ rsync_file_size.rb -H somehost -P somedir/anotherdir/ -w "0:5"
EOD

@options = {}

@opts = OptionParser.new

@opts.on(
  "-H", "--hostname HOSTNAME", "Hostname"
) { |value| @options[:hostname] = value }

@opts.on(
  "-P", "--path PATH", "Path to Query"
) { |value| @options[:path] = value}

@opts.on(
  "-w", "--warning WARNING", "Return warning if outside this range"
) { |value| @options[:warning] = value }

@opts.on(
  "-c", "--critical CRITICAL", "Return critical if outside this range"
) { |value| @options[:critical]= value }

@opts.on(
  '-r', "--recursive", "Search recursively"
) { |value| @options[:recursive] = true }

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
  begin
    nagios = nagios_check_size(get_files)
    nagios.message = "#{nagios.result} files #{nagios.threshold} MB in size"
    nagios
  rescue Exception => e
    puts "CRITICAL: #{e.message[0,68]}"
    exit(2)
  end
end

def nagios_check_size(list)
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  files = []
  list.results.each do |file|
    if file.is_file?
      files << check.compare(file.size_mb)
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

