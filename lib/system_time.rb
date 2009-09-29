require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemTime
  
  # hrSystemDate
  OID_BASE = ".1.3.6.1.2.1.25.1.2.0"
  
  attr_reader :time
  
  def initialize(time)
    @time = time
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.get(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    parts = r.stdout.split('=')
    SystemTime.new(self.snmp_to_time(parts[1].strip!))
  end
  
  def to_s
    @time.to_s
  end
    
  private 
  def self.snmp_to_time(string)
    unless /(\d){4}-(\d){1,2}-(\d){1,2},(\d){1,2}:(\d){1,2}:(\d){1,2}.(\d){1}/.match(string)
      raise "Invalid Time Format"
    end
    parts = string.split(',')
    date = parts[0].split('-')
    year = date[0]
    month = date[1]
    day = date[2]
    time = parts[1].split(':')
    hour = time[0]
    min = time[1]
    seconds = time[2].split('.')
    sec = seconds[0]
    usec = seconds[1]
    Time.local(year,month,day,hour,min,sec,usec)
  end
  
end
  
