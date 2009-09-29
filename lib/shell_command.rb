require 'rubygems'
require 'open4'
class ShellCommand

  attr_reader :pid, :stdout, :stderr, :status
  attr_accessor :command, :results
  
  def initialize(cmd)
    @command = find_command(cmd)
  end

  def run(parameters)
    status = Open4::popen4("#{@command} #{parameters}") do 
    |pid, stdin, stdout, stderr|
      @pid = pid
      @stdout = stdout.read.strip
      @stderr = stderr.read.strip
    end
    @status = status.exitstatus
    return self
  end

  private
  
  def find_command(cmd)
    command = nil
    safe_path  = File.join(File.dirname(__FILE__), "..", 'libexec')
    if(test(?x, "#{safe_path}/#{cmd}"))
      command = "#{safe_path}/#{cmd}"
    end
    if command.nil?
      raise(
        StandardError, 
        "Cannot find #{cmd}, specify full path or symlink in ./libexec"
      )
    end
    command
  end

end
