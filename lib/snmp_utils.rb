require File.join(File.dirname(__FILE__), 'shell_command')
require 'yaml'
class SnmpUtils
  
  @@config = YAML.load_file(File.join(File.dirname(__FILE__), '..', 'etc', 'snmp.yml'))
  
  def initialize(host)
    if @@config['host']
      community = @@config['host']['community']
    else
      community = @@config['default']['community']
    end
    @host = host
    @snmpwalk = ShellCommand.new("snmpwalk")
    @snmpget  = ShellCommand.new("snmpget")
    @parameters = "-v2c -On -OQ -OU -c #{community}"
  end

  def walk(oid)
    r = @snmpwalk.run("#{@parameters} #{@host} #{oid}")
  end
  
  def get(oid)
    r = @snmpget.run("#{@parameters} #{@host} #{oid}")
  end
end
