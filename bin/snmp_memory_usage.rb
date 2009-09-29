#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_memory_usage')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_process')

include CommandHelper

@details = <<EOD
Description:
  Check the memory utilization of processes and return nagios check states
  if results are outside the specified ranges. Check ranges are in MB.

Example:
  Check the processes running on somehost.  Warn if more than
  80MB of RAM is being used in one process.  Critical if more than 
  100MB are in use by any process.

  $ snmp_memory_usage.rb -H somehost -w "~:80" -c "~:100"
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
  "-P", "--process PROCESS", "Limit checks to a process regex"
) { |value| @options[:process] = value }

@opts.on(
  "-N", "--negate", "Negate the process regex"
) { |value| @options[:negate] = true }

@opts.on(
  "-v", "--verbose", "Print out all memory usage"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }


def get_processes
  memory = SystemMemoryUsage.find_by_host(@options[:hostname])
  process_memory = []
  @process_name = nil
  if @options[:process] && !@options[:process].empty?
    process = SystemProcess.find_by_host(@options[:hostname])
    process = match_process(process,@options)
    process.each do |p|
      if pm = memory.detect {|m| m.pid == p.pid}
        pm.name = p.name
        process_memory << pm
      end
    end
    process_memory
  else
    memory
  end
end

def match_process(collection)
  if @options[:negate]
    @process_name = " of NOT #{@options[:process]}"
    collection.reject {|s| Regexp.new(@options[:process],true).match(s.name)}
  else
    @process_name = " of #{@options[:process]}"
    collection.select {|s| Regexp.new(@options[:process],true).match(s.name)}
  end
end

def check_memory
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  process = get_processes
  results = []
  process.each do |p|
    results << check.compare(p.memory_mb)
  end
  crit = results.select {|r| r.kind_of? NagiosResult::Critical }.length
  warn = results.select {|r| r.kind_of? NagiosResult::Warning }.length
  if crit > 0
    return NagiosResult::Critical.new(check.critical[:output],crit)
  end
  if warn > 0
    return NagiosResult::Warning.new(check.warning[:output],warn)
  end
  return NagiosResult::Ok.new(check.ok[:output],0)
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
    nagios = check_memory
    nagios.message = "#{nagios.result} processes#{@process_name} consuming #{nagios.threshold} MB memory"
    print_results(nagios)
  end
rescue StandardError => e
  print_exception(e)
end

