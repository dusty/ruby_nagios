module NagiosResult
  
  attr_reader   :threshold, :result, :state, :code
  attr_accessor :message
  
  def to_xml
    xml = ::Builder::XmlMarkup.new(:indent=>2)
    xml.result do
      xml.threshold   threshold
      xml.result      result
      xml.state       state
      xml.code        code
      xml.message     message
    end
  end
  
  def output
    "#{state}: #{message}"
  end
  
  alias to_s output
  
end

module NagiosResult
    
  class Ok
    
    include NagiosResult
    
    def initialize(threshold=nil,result=nil)
      @threshold, @result = threshold, result
      @state = "OK"
      @code = 0
    end
  end

  class Warning

    include NagiosResult

    def initialize(threshold=nil,result=nil)
      @threshold, @result = threshold, result
      @state = "WARNING"
      @code = 1
    end
  end

  class Critical

    include NagiosResult

    def initialize(threshold=nil,result=nil)
      @threshold, @result = threshold, result
      @state = "CRITICAL"
      @code = 2
    end
  end

  class Unknown

    include NagiosResult

    def initialize(threshold=nil,result=nil)
      @threshold, @result = threshold, result
      @state = "UNKNOWN"
      @code = 3
    end
  end
  
end
