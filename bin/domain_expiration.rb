#!/usr/bin/env ruby
require 'optparse'
require 'rubygems'
require 'whois'
require 'date'
require File.join(File.dirname(__FILE__), "..", 'lib', 'command_helper')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_check')
require File.join(File.dirname(__FILE__), "..", 'lib', 'nagios_result')

include CommandHelper

@details = <<EOD
Description:
  Check the expiration date of a domain. 

Example:
  Check the expiration of mydomain.com.  
  Warn if less than 28 days.  Crit if less than 14 days.

  $ domain_expiration.rb -D mydomain.com -w "14:" -c "28:" 
 
EOD

@options = {}
# Default
@opts = OptionParser.new

@opts.on(
  "-D", "--domain Domain", "Domain"
) { |value| @options[:domain] = value }

@opts.on(
  "-w", "--warning WARNING", "Return warning if outside this range"
) { |value| @options[:warning] = value }

@opts.on(
  "-c", "--critical CRITICAL", "Return critical if outside this range"
) { |value| @options[:critical]= value }

@opts.on(
  "-v", "--verbose", "Print out whois results"
) { |value| @options[:verbose] = true }

@opts.on(
  "-h", "--help", "Show Command Help"
) { |v| print_details }

@opts.on(
  "-R", "--ranges", "Show Ranges Help"
) { |v| print_ranges }

def results
  @results ||= Whois::Client.new.query(@options[:domain])
end

def expiration_days
  @expiration_days ||= ((results.expires_on - Time.now) / 86400).round
end

def nagios_results
  warn = @options[:warning] ? (@options[:warning]) : nil
  crit = @options[:critical] ? (@options[:critical]) : nil
  check = NagiosCheck.new(@options[:warning], @options[:critical])
  nagios = check.compare(expiration_days)
  nagios.message = "#{@options[:domain]} expires in #{expiration_days} days"
  nagios
end

begin
  @opts.parse!
rescue StandardError => e
  print_help("Error: #{e.message}") unless e.message == "exit"
end

unless @options[:domain]
  print_help("Missing Argument: domain is required.")
end

begin
  if @options[:verbose]
    puts results
  else
    print_results(nagios_results)
  end
rescue StandardError => e
  print_exception(e)
end

