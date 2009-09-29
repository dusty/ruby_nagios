#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_process')

include CommandHelper

@details = <<EOD
Description:
  Check the number of processes matching a regex and return nagios
  check states if results are outside the specified ranges.  If the
  process is not specified, then all processes will be considered.

Example:
  Check for the httpd process running on somehost. Warn if more than
  10 processes are running.  Critical if more than 15 processes are
  running or less than 1 process is running.
  
  $ snmp_process.rb -H somehost -P httpd -w "~:10" -c "1:15"
EOD

@options = {}

@opts = OptionParser.new

@opts.on(
  "-H", "--hostname HOSTNAME", "Hostname"
) { |value| @options[:hostname] = value }

@opts.on(
  "-w", "--warning WARNING", "Return warning if outside this range"
) { |value| @options[:warning] = value }

@opts.on(
  "-c", "--critical CRITICAL", "Return critical if outside this range"
) { |value| @options[:critical] = value }

@opts.on(
  "-P", "--process PROCESS", "Process to check for"
) { |value| @options[:process] = value }

@opts.on(
  "-N", "--negate", "Negate the process regex"
) { |value| @options[:negate] = true }

@opts.on(
  "-v", "--verbose", "Print out all processes"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }


def get_processes
  process = SystemProcess.find_by_host(@options[:hostname])
  @process_name = nil
  if @options[:process] && !@options[:process].empty?
    process = match_process(process)
  end
  process
end

def match_process(collection)
  if @options[:negate]
    @process_name = "of NOT #{@options[:process]}"
    collection.reject {|s| Regexp.new(@options[:process],true).match(s.name)}
  else
    @process_name = "of #{@options[:process]}"
    collection.select {|s| Regexp.new(@options[:process],true).match(s.name)}
  end
end

def check_process
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  process = get_processes
  nagios = check.compare(process.length)
  nagios.message = "#{nagios.result} running processes #{@process_name}"
  nagios
end

begin
  @opts.parse!
rescue StandardError => e
  print_help("Error: #{e.message}") unless e.message == "exit"
end

unless @options[:hostname]
  print_help("Missing Arguments: hostname is required.")
end

begin
  if @options[:verbose]
    puts get_processes
  else
    print_results(check_process)
  end
rescue StandardError => e
  print_exception(e)
end

