require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemUptime
  
  # sysUpTimeInstance
  OID_BASE = ".1.3.6.1.2.1.1.3.0"
  
  attr_reader :timeticks

  def initialize(timeticks)
    @timeticks = timeticks
  end

  def minutes
    @timeticks / 6000
  end

  def seconds
    @timeticks / 100
  end

  def hours
    @timeticks / 360000
  end
  
  def days
    @timeticks / (360000 * 24)
  end 
  
  def to_s
    days, remainder = @timeticks.divmod(8640000)
    hours, remainder = remainder.divmod(360000)
    minutes, remainder = remainder.divmod(6000)
    seconds, hundredths = remainder.divmod(100)
    sprintf('%d days, %d hours, %d minutes, %d.%d seconds',
            days, hours, minutes, seconds, hundredths)
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.get(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    parts = r.stdout.split('=')
    SystemUptime.new(self.snmp_to_timeticks(parts[1].strip!))
  end
    
  private
  def self.snmp_to_timeticks(string)
    parts = string.split(':')
    days = parts[0].to_i
    hours = parts[1].to_i
    mins = parts[2].to_i
    secs = parts[3].to_f
    timeticks  = days  * 24 * 60 * 60 * 100
    timeticks += hours * 60 * 60 * 100
    timeticks += mins  * 60 * 100
    timeticks += secs  * 100
    timeticks.to_i
  end
  
end
