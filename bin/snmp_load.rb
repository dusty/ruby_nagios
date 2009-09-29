#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_load')

include CommandHelper

@details = <<EOD
Description:
  Check the system load of a host and return nagios check states if 
  results are outside the specified ranges. 
 
  The warning and critical arguments default to the 1 minute load unless
  otherwise specified. The last load type argument will take precen
 

Example:
  Warning if over 1.5, Critical if over 2.5
  $ snmp_load.rb -H somehost -w "~:1.5" -c "~:2.5"
EOD

@options = {}

@opts = OptionParser.new

@opts.on(
  "-H", "--hostname HOSTNAME", "Hostname to check"
) { |v| @options[:hostname] = v }

@opts.on(
  "-w", "--warning WARNING", "Return warning if outside this range"
) { |v| @options[:warning] = v }

@opts.on(
  "-c", "--critical CRITICAL", "Return critical if outside this range"
) { |v| @options[:critical]= v }

@opts.on(
  "-l", "--load LOAD", "Check 1, 5, or 15 minute load (default 1)"
) { |v| @options[:load] = v }

@opts.on(
  "-v", "--verbose", "Print out system load"
) { |v| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }


def get_load
  SystemLoad.find_by_host(@options[:hostname])
end

def check_load
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  load = get_load
  nagios = check.compare(load.load[@options[:load]])
  nagios.message = "load average: #{load}"
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

@options[:load] ||= "1"
unless /^(1|5|15)$/.match(@options[:load])
  print_help("Invalid Arguments: load must be 1, 5, 15")
end

begin
  if @options[:verbose]
    puts get_load
  else
    print_results(check_load)
  end
rescue StandardError => e
  print_exception(e)
end

