require File.join(File.dirname(__FILE__), 'mock_file')
require File.join(File.dirname(__FILE__), 'shell_command')
require 'parsedate'
class RsyncUtils

  def initialize(timeout=4)
    @timeout = timeout
    @rsync = ShellCommand.new("rsync")
  end
  
  def list(host)
    raise "Invalid Path" unless check_host(host)
    r = @rsync.run("--contimeout=#{@timeout} #{host}::")
    raise "#{r.stderr}" unless r.status == 0
    r
  end
  
  def show(host,path,recurs=false)
    recursive = "--recursive" if recurs
    raise "Invalid Path" unless check_host(host)
    if path
      raise "Invalid Path" unless check_path(path)
    end
    r = @rsync.run("--contimeout=#{@timeout} #{recursive} #{host}::#{path}")
    raise "#{r.stderr}" unless r.status == 0
    files = []
    r.stdout.each do |line|
      parts = line.split
      case parts[0]
      when /^[rwx-]{10}$/
        type = "File"
      when /^d[rwx-]{9}$/
        type = "Directory"
      else
        type = "Module" 
      end
      if type != "Module"
        time = Time.local(*ParseDate::parsedate("#{parts[2]} #{parts[3]}"))
        size = parts[1].to_i
        name = parts[4]
      else
        time = Time.now
        size = 0
        name = parts[0]
      end
      files << MockFile.new(name,type,time,size)
    end
    r.results = files     
    r
  end
  
  private
  
  def check_host(host)
    /^([a-zA-Z0-9\-\.]+)$/.match(host)
  end
  
  def check_path(path)
    /^([a-zA-Z0-9\-\.\/_]+)$/.match(path)
  end
  
end
