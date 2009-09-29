require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemProcess
  
  # hrSWRun
  OID_BASE       = ".1.3.6.1.2.1.25.4.2.1"
  OID_INDEX      = OID_BASE + ".1"
  OID_NAME       = OID_BASE + ".2"
  OID_ID         = OID_BASE + ".3"
  OID_PATH       = OID_BASE + ".4"
  OID_PARAMETERS = OID_BASE + ".5"
  OID_TYPE       = OID_BASE + ".6"
  OID_STATUS     = OID_BASE + ".7"
  
  attr_reader   :pid
  attr_accessor :name, :path, :parameters, :type, :status
  
  def initialize(pid)
    @pid = pid
  end
    
  def to_s
    <<EOD
#{pid}\t#{name}
EOD
  end
  
  def to_xml
    xml = Builder::XmlMarkup.new(:indent=>2)
    xml.process do
      xml.pid = pid
      xml.name = name
    end
  end
  
  def self.find_all_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    matches = Hash.new
    r.stdout.each do |line|
      parts = line.split('=')
      parts.collect! {|part| part.delete('"').strip! }
      case parts[0]
      when /^#{Regexp.escape(OID_INDEX)}\.(\d+)$/
        matches[$1.to_i] = SystemProcess.new($1.to_i)
      when /^#{Regexp.escape(OID_NAME)}\.(\d+)$/
        matches[$1.to_i].name = parts[1]
      when /^#{Regexp.escape(OID_PATH)}\.(\d+)$/
        matches[$1.to_i].path = parts[1]
      when /^#{Regexp.escape(OID_PARAMETERS)}\.(\d+)$/
        matches[$1.to_i].parameters = parts[1]
      when /^#{Regexp.escape(OID_TYPE)}\.(\d+)$/
        matches[$1.to_i].type = parts[1]
      when /^#{Regexp.escape(OID_STATUS)}\.(\d+)$/
        matches[$1.to_i].status = parts[1]
      end
    end
    processes = Array.new
    matches.keys.each {|k| processes << matches[k]}
    processes
  end
  
  def self.find_by_host(host)
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_PATH)
    raise "#{r.stderr}" unless r.status == 0
    processes = []
    r.stdout.each do |line|
      parts = line.split('=')
      parts.collect! {|part| part.delete('"').strip! }
      p = SystemProcess.new(parts[0].split('.').last.to_i)
      p.name = parts[1]
      processes << p
    end
    processes
  end
  
  def self.find_by_pid(collection)
    collection.detect {|c| c.pid == pid }
  end
  
end
