#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_time')

include CommandHelper

@details = <<EOD
Description:
  Check the time difference between a remote machine and local machine and 
  nagios check states if results are outside the specified ranges.  Time is
  checked in seconds.

Example:
  Check for the remote time on somehost. Return a warning if more than 10 
  seconds different than the local machine.  Return a critical state if more
  than 15 seconds different.
   
  $ snmp_time.rb -H somehost -w "10" -c "15"
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
  "-v", "--verbose", "Print out the system time"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }


def get_time
  SystemTime.find_by_host(@options[:hostname])
end

def check_time
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  time = get_time
  now = Time.now
  diff = "%.2f" % (now - time.time).abs
  nagios = check.compare(diff)
  nagios.message = "Time difference is #{nagios.result} seconds"
  nagios
end

begin
  @opts.parse!
rescue StandardError => e
  print_help("Error: #{e.message}")
end

unless @options[:hostname]
  print_help("Missing Arguments: hostname is required.")
end

begin
  if @options[:verbose]
    puts get_time
  else
    print_results(check_time)
  end
rescue StandardError => e
  print_exception(e)
end

