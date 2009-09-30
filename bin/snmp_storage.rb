#!/usr/bin/env ruby
require 'optparse'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')
require File.join(File.dirname(__FILE__), "..", 'lib', 'system_storage')

include CommandHelper

@details = <<EOD
Description:
  Check the free disk space in Megabytes and return nagios check states 
  if results are outside the specified ranges.  By default the check is
  in Megabytes free.  Specify --percent if you wish to check % free.

Example:
  Check for c: on somehost. Return a warning state if disk free is less than
  10000M.  Return a critical state if disk free is less than 5000M.

  $ snmp_storage.rb -H somehost -l "c:" -w "5000:" -c "10000:"
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
  "-l", "--label LABEL", "Disk Label to Check, All if not specified"
) { |value| @options[:label] = value }

@opts.on(
  "-P", "--percent", "Check for percentage instead of Mb"
) { |value| @options[:percent] = true }

@opts.on(
  "-v", "--verbose", "Print out all storage usage"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }

def get_storage
  storage = SystemStorage.find_by_host(@options[:hostname])
  if @options[:label]
    storage = storage.select do |s|
      Regexp.new(@options[:label],true).match(s.label)
    end
  end
  storage
end

def check_storage
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  storage = get_storage
  if storage.length > 1
    nagios = check.compare(nil)
    nagios.message = "Multiple matches on label"
  else
    if @options[:percent]
      comp = storage.first.free_percent
      display = "%"
    else
      comp = storage.first.free_mb
      display = "M"
    end
    nagios = check.compare(comp)
    label = @options[:label].delete('^').delete('$')
    nagios.message = "#{nagios.result} #{display} of disk free on #{label}"
  end
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
    puts get_storage
  else
    print_results(check_storage)
  end
rescue StandardError => e
  print_exception(e)
end

