require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemCpu
  
  OID_BASE = ".1.3.6.1.2.1.25.3.3.1.2"
  
  attr_reader :id, :used_percent
  
  def initialize(id,used)
    @id,@used_percent = id,used
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    cpus = []
    r.stdout.each do |line|
      parts = line.split('=')
      parts.collect! {|part| part.delete('"').strip! }
      p = SystemCpu.new(parts[0].split('.').last.to_i, parts[1].to_i)
      cpus << p
    end
    cpus
  end
  
  def to_s
    "id: #{@id}\n  used_percent: #{@used_percent}\n\n"
  end
  
  def to_xml
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.cpu do
      xml.id id
      xml.used_percent @used_percent
    end
  end
    
end
