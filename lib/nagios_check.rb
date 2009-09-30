class NagiosCheck

  INFINITY = 1.0/0
  NEGATIVE_INFINITY = -1.0/0

  attr_reader :warning, :critical, :ok

  def initialize(warning,critical)
    @warning = load_check(warning)
    @critical = load_check(critical)
    okout = @warning[:output] || @critical[:output] || "== 0"
    @ok = {:thresholds => [], :output => okout }
  end
  
  def compare(result)
    unless do_compare(@critical,result)  
      return NagiosResult::Critical.new(@critical[:output],result)
    end
    unless do_compare(@warning,result)
      return NagiosResult::Warning.new(@warning[:output],result)
    end
    return NagiosResult::Ok.new(@ok[:output],result)
  end

  private
  
#  10      =  fail when < 0 or > 10      |  outside range of { 0..10 }
#  10:     =  fail when < 10             |  outside range of { 10..Infinity }
#  ~:10    =  fail when > 10             |  outside range of { -Infinity..10 }
#  10:20   =  fail when < 10 OR > 20     |  outside range of { 10..20 }
#  @10:20  =  fail when >= 10 AND <= 20  |  inside  range of { 10..20 }
#  true    =  fail when true
#  false   =  fail when false
  def load_check(param)
    args = []
    output = nil
    param = param.strip if param 
    case param
    when /^\d+$/ 
      args << [0,param.to_f]
      output = "(lt 0 OR gt #{param})"
    when /^\d+:$/
      arg = param.split(/:/)[0]
      args << [arg.to_f,INFINITY]
      output = "(lt #{arg})"
    when /^~:\d+$/
      arg = param.split(/:/)[1]
      args << [NEGATIVE_INFINITY,arg.to_f]
      output = "(gt #{arg})"
    when /^\d+:\d+$/
      arg = param.split(/:/)
      args << [arg[0].to_f,arg[1].to_f]
      output = "(lt #{arg[0]} OR gt #{arg[1]})"
    when /^@\d+:\d+$/
      arg = param.split(/:/)
      arg[0] = arg[0].sub(/@/,'')
      args << [NEGATIVE_INFINITY,arg[0].to_f - 1]
      args << [arg[1].to_f + 1,INFINITY]
      output = "(gt= #{arg[0]} AND lt= #{arg[1]})"
    when "true"
      args << [false]
      output = "(== true)"
    when "false"
      args << [true]
      output = "(== false)"
    end
    check = {:thresholds => args, :output => output}
  end
  
  def do_compare(check,result)
    count = 0
    count = 1 if check[:thresholds].size == 1
    check[:thresholds].each do |arg|
      case result
      when nil
        return false
      when false
        return result == arg[0]
      when true
        return result == arg[0]
      else
        if(result.to_f < arg[0] or result.to_f > arg[1])
          count = count + 1
        end
      end
    end
    return false if count == 2
    return true
  end
  
end


  
