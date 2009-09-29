module CommandHelper

  def print_ranges
    puts <<-EOD
Ranges

 Description:
   Ranges are defined as a start and end point on a numeric scale.  The
   generalized format for a range is:

   [@]start:end

   Ranges are normally considered to be exclusive and the check will fail
   when outside the range.  If the range starts with @, then the check will
   be inclusive and the check will fail when inside the range.  If start = 0,
   then start and : are not required.  If range is in the format of start:,
   then end is assumed to be infinity.  To specify negative infinity use ~.

   For simple boolean checks, you should specify what you want to fail.  For
   example, warning = true will fail when the result is true.  If warning =
   false the check will fail when the result is false.

 Examples:
   10      =  alert when < 0 or > 10     | outside range of { 0..10 }
   10:     =  alert when < 10            | outside range of { 10..Infinity }
   ~:10    =  alert when > 10            | outside range of { -Infinity..10 }
   10:20   =  alert when < 10 OR > 20    | outside range of { 10..20 }
   @10:20  =  alert when >= 10 AND <= 20 | inside  range of { 10..20 }
   true    =  alert when true
   false   =  alert when false

   EOD
    exit(3)
  end
  
  def print_details
    puts "\n#{@details}\n"
    puts "#{@opts}\n"
    exit(3)
  end
  
  def print_help(message)
    puts "\n#{message}\n\n"
    puts "#{@opts}\n"
    exit(3)
  end
  
  def print_results(nagios)
    puts nagios.output
    exit(nagios.code)
  end

  def print_exception(exception)
    puts "EXCEPTION: #{exception.message[0,68]}"
    exit(2)
  end
  
end
