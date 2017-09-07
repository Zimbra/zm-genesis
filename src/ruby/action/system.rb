#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#
# Part of the command class structure.  This is the interface to os level
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
 
module Action # :nodoc

  #
  # Perform zmprov action.  This will invoke some system command with arguments
  # from http server
  #
  class System < Action::Command
  
    #
    #  Create a System object.
    #
    attr_reader :response
    attr :exitstatus, true
    
    def initialize(programName, context = ZIMBRAUSER, *arguments)
      super()
      #@arguments = arguments
      @encoding = nil
      @arguments = arguments.delete_if {|w| @encoding = w if w.kind_of? Encoding}
      @programName = programName
      @context = context
      @response = nil
      @exitstatus = 0
      @su = nil
      if(not (RUBY_PLATFORM =~ /win32/)) 
        if (RUBY_PLATFORM =~ /darwin/)
           @su = "/bin/su - #{@context} -l -c "
        else  
           @su = "/bin/su - #{@context} -c "
        end 
      end
    end
    
    #
    #  Perform execution
    #
    def run  
      processed_arg = @arguments.map { |x| 
        if( (x.class == Proc) || (x.class == Method))
          x.call
        else
          x
        end
      }        
      begin
        if(@su)
          puts   "#{@su} '#{@programName} #{processed_arg.join(' ')}' 2>&1" if $DEBUG 
          @response =  `#{@su} '#{@programName} #{processed_arg.join(' ')}' 2>&1` 
        else
          @response =  `#{@programName} #{processed_arg.join(' ')} 2>&1` 
        end
        @response = @encoding.nil? ? @response : @response.force_encoding(@encoding)
        @exitstatus =  $?.exitstatus
      rescue => e
        @response = e.to_s + e.backtrace.join("\n")
        @exitstatus = 1
      end 
      [@exitstatus, @response, '']        
    end
    
    def to_str
      processed_arg = @arguments.map { |x| 
        if( (x.class == Proc) || (x.class == Method))
          x.call
        else
          x
        end
      } 
      "Action:#{@programName} #{processed_arg.join(' ')}"
    end
    
    def to_s
      to_str
    end
  end 
end

if $0 == __FILE__
  require 'test/unit'
  
  module Action
    #
    # Unit test case for GetBuild object
    class SystemTest < Test::Unit::TestCase
      def testRun
        testObject = Action::System.new('dirs') 
        testObject.run
        puts YAML.dump(testObject.response)
        assert(testObject.response.include("not"), "fail path")
      end
      
      def testDelay
        testString = "c:"
        testObject = Action::System.new('dir', Action::Command::ZIMBRAUSER, testString.method("to_str")) 
        testObject.run
      end
      
      def testTOS
        testObject = Action::System.new('ls', Action::Command::ZIMBRAUSER, 'ca yes')
        puts testObject
      end
      
      def testTimeOut
        testObject = Action::System.new('dirs')
        puts testObject.timeOut
      end
    end
  end
end


 