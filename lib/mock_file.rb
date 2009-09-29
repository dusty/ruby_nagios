class MockFile

  attr_reader :name, :type, :time, :size

  def initialize(name,type,time,size)
    @name = name
    @time = time
    @size = size
    @type = type
  end

  def is_file?
    @type == "File"
  end

  def is_dir?
    @type == "Directory"
  end
  
  def is_module?
    @type == "Module"
  end
  
  def size_mb
    @size_mb ||= (size / 1024 / 1024)
  end
    
  def to_s
    <<EOD
---
name: #{name}
size: #{size}
time: #{time}
type: #{type}
EOD
  end
  
end