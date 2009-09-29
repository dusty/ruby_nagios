#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_uptime')

include CommandHelper

@details = <<EOD
Description:
  Check the uptime of a remote host and generate nagios states if the uptime 
  in minutes is outside the specified ranges.

Example:
  Check for the uptime on somehost. Return a warning state if over 1440
  minutes since last restart.  Return a critical state if under 5 minutes
  since last restart.
  
  $ snmp_uptime.rb -H somehost -w "~:1440" -c "5:"
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
  "-v", "--verbose", "Print out all the system uptime"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }


def get_uptime
  SystemUptime.find_by_host(@options[:hostname])
end

def check_uptime
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  uptime = get_uptime
  nagios = check.compare(uptime.minutes)
  nagios.message = "Uptime is #{uptime}"
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
    puts get_uptime
  else
    print_results(check_uptime)
  end
rescue StandardError => e
  print_exception(e)
end
