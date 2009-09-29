require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemLoad
  
  OID_BASE = ".1.3.6.1.4.1.2021.10.1.3"
  OID_1  = OID_BASE + ".1"
  OID_5  = OID_BASE + ".2"
  OID_15 = OID_BASE + ".3"
  
  attr_reader :load
  
  def initialize(load)
    @load = load
    raise(StandardError, "Invalid argument") unless @load.is_a?(Hash)
  end
  
  def one
    load["1"]
  end
  
  def five
    load["5"]
  end
  
  def fifteen
    load["15"]
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    load = {}
    r.stdout.each do |line|
      parts = line.split('=')
      case parts[0].strip
      when OID_1
        load["1"]  = parts[1].to_f
      when OID_5
        load["5"]  = parts[1].to_f
      when OID_15
        load["15"] = parts[1].to_f
      end
    end
    SystemLoad.new(load)
  end
  
  def to_s
    "#{one}, #{five}, #{fifteen}"
  end
  
  def to_xml
    raise NotImplementedError
  end
    
end
