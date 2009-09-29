require File.join(File.dirname(__FILE__), 'snmp_utils')
class SystemStorage
  
  # hrStorage
  OID_BASE           = ".1.3.6.1.2.1.25.2.3.1"
  OID_INDEX          = OID_BASE + ".1"
  OID_TYPE           = OID_BASE + ".2"
  OID_DESCRIPTION    = OID_BASE + ".3"
  OID_UNITS          = OID_BASE + ".4"
  OID_SIZE           = OID_BASE + ".5"
  OID_USED           = OID_BASE + ".6"
  OID_FAILURES       = OID_BASE + ".7"
  
  # Storage Types
  OID_TYPE_BASE      = ".1.3.6.1.2.1.25.2.1"
  OID_TYPE_OTHER     = OID_TYPE_BASE + ".1"
  OID_TYPE_RAM       = OID_TYPE_BASE + ".2"
  OID_TYPE_VIRTUAL   = OID_TYPE_BASE + ".3"
  OID_TYPE_FIXED     = OID_TYPE_BASE + ".4"
  OID_TYPE_REMOVABLE = OID_TYPE_BASE + ".5"
  OID_TYPE_FLOPPY    = OID_TYPE_BASE + ".6"
  OID_TYPE_COMPACT   = OID_TYPE_BASE + ".7"
  OID_TYPE_RAM_DISK  = OID_TYPE_BASE + ".8"
  OID_TYPE_FLASH     = OID_TYPE_BASE + ".9"
  OID_TYPE_NETWORK   = OID_TYPE_BASE + ".10"
  

  attr_reader   :id, :type
  attr_accessor :label, :block_size, :total_blocks, :used_blocks, :failures
  
  def initialize(id)
    @id = id
  end
  
  def size
    @size ||= (block_size * total_blocks)
  end
  
  def used
    @used ||= (block_size * used_blocks)
  end
  
  def free
    @free ||= (size - used)
  end
    
  def size_mb
    @size_mb ||= (size / 1024 / 1024)
  end
  
  def used_mb
    @used_mb ||= (used / 1024 / 1024)
  end
  
  def free_mb
    @free_mb ||= (size_mb - used_mb)
  end
  
  def used_percent
    @used_percent ||= get_used_percent
  end

  def free_percent
    @free_percent ||= get_free_percent
  end
  
  def type=(type)
    @type = find_type(type)
  end
  
  def block_size
    @block_size ||= 0
  end
  
  def total_blocks 
    @total_blocks ||= 0
  end
  
  def used_blocks
    @used_blocks ||= 0
  end
  
  def to_s
    <<EOD
---
id: #{id}
label: #{label}
type: #{type}
size: #{size_mb}M
used: #{used_mb}M
free: #{free_mb}M
percent_used: #{used_percent}%
percent_free: #{free_percent}%
EOD
  end
  
  def self.find_by_host(host)
    disks = []
    snmp = SnmpUtils.new(host)
    r = snmp.walk(OID_BASE)
    raise "#{r.stderr}" unless r.status == 0
    matches = Hash.new
    r.stdout.each do |line|
      parts = line.split('=')
      parts.collect! {|part| part.delete('"').strip! }
      case parts[0]
      when /^#{Regexp.escape(OID_INDEX)}\.(\d+)$/
        matches[$1.to_i] = SystemStorage.new($1.to_i)
      when /^#{Regexp.escape(OID_TYPE)}\.(\d+)$/
        matches[$1.to_i].type = parts[1].to_s
      when /^#{Regexp.escape(OID_DESCRIPTION)}\.(\d+)$/
        matches[$1.to_i].label = parts[1].to_s
      when /^#{Regexp.escape(OID_UNITS)}\.(\d+)$/
        matches[$1.to_i].block_size = parts[1].to_i
      when /^#{Regexp.escape(OID_SIZE)}\.(\d+)$/
        matches[$1.to_i].total_blocks = parts[1].to_i
      when /^#{Regexp.escape(OID_USED)}\.(\d+)$/
        matches[$1.to_i].used_blocks = parts[1].to_i
      when /^#{Regexp.escape(OID_FAILURES)}\.(\d+)$/
        matches[$1.to_i].failures = parts[1].to_i
      end
    end
    disks = Array.new
    matches.keys.each {|k| disks << matches[k]}
    disks
  end
    
  private  
  def find_type(type)
    case type
    when OID_TYPE_OTHER
      "Other"
    when OID_TYPE_RAM
      "Ram"
    when OID_TYPE_VIRTUAL
      "Virtual Memory"
    when OID_TYPE_FIXED
      "Fixed Disk"
    when OID_TYPE_REMOVABLE
      "Removable Disk"
    when OID_TYPE_FLOPPY
      "Floppy Disk"
    when OID_TYPE_COMPACT
      "Compact Disk"
    when OID_TYPE_RAM_DISK
      "Ram Disk"
    when OID_TYPE_FLASH
      "Flash Memory"
    when OID_TYPE_NETWORK
      "Network Disk"
    else
      "Unknown"
    end
  end
  
  def get_used_percent
    if size == 0
      0
    else
      ((used.to_f / size.to_f) * 100).round
    end
  end
  
  def get_free_percent
    if size == 0
      0
    else
      ((free.to_f / size.to_f) * 100).round
    end
  end
  
end