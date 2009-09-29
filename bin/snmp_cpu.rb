#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_cpu')

include CommandHelper

@details = <<EOD
Description:
  Check the CPU utilization of a host and return nagios
  check states if results are outside the specified ranges.

Example:
  Check for CPU utilization on somehost. Warn if more than
  50%, critical if more than 75%.

  $ snmp_cpu.rb -H somehost -w "~:50" -c "~:75"
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
  "-v", "--verbose", "Print out all cpu usage"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }

def get_cpu
  SystemCpu.find_by_host(@options[:hostname])
end

def check_cpu
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  cpus = get_cpu
  max = cpus.max {|a,b| a.used_percent <=> b.used_percent}
  nagios = check.compare(max.used_percent)
  nagios.message = "Max CPU Utilization at #{nagios.result} %"
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
    puts get_cpu
  else
    print_results(check_cpu)
  end
rescue StandardError => e
  print_exception(e)
end

