require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemMemoryUsage
  
  # hrSWRunPerfMem
  OID_BASE       = ".1.3.6.1.2.1.25.5.1.1.2"
  
  attr_reader   :pid
  attr_accessor :memory, :name
  
  def initialize(pid)
    @pid = pid
  end
  
  def memory_mb
    memory / 1024
  end
    
  def to_s
    <<EOD
#{pid}\t#{memory}\t#{name}
EOD
  end
  
  def to_xml
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.process do
      xml.pid = pid
      xml.memory(memory, :units => "K")
    end
  end
  
  def find_by_pid(collection)
    collection.detect {|c| c.pid == pid }
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    processes = []
    r.stdout.each do |line|
      parts = line.split('=')
      parts.collect! {|part| part.delete('"').strip! }
      p = SystemMemoryUsage.new(parts[0].split('.').last.to_i)
      p.memory = parts[1].to_i
      processes << p
    end
    processes
  end
  
end
