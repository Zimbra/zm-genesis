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
# Part of the command class structure.  Verify class does response validation
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'yaml'
 
module Action # :nodoc
  #
  #  Perform proxy wrapping on some method
  #
  class Verify  
    attr :check, true
    attr :pass, true
    attr :lineNumber, true
    attr :message, true  
    attr :timeOut, true
    
    #
    # Objection creation
    # create method wrapper
    def initialize(*argv, &verifylogic)
      super()
      timeOutOne = timeOutTwo = 60
      if(argv.size > 0)
        @provider = argv[0]
        begin
          timeOutTwo = @provider.timeOut
        rescue
      
        end  
      end
    
      if(argv.size > 1 && (argv[1].class == Fixnum))
        timeOutOne = argv[1]
      end
         
      @timeOut = timeOutOne + timeOutTwo
      @verifylogic = verifylogic      
      self.check = true
    end
    
    def pass=(value)
      @pass = value
      self.lineNumber = caller.first
    end

    def suppressDump(reason = 'skipped, please debug')
      @provider = reason
    end
    
    def run  
      begin
        result = @provider.run
        return self if @verifylogic.nil?
        @verifylogic.call(self, result) 
      rescue => detail
        self.pass = false
        self.message = detail.message + detail.backtrace.join("\n")
      end        
      self
    end
            
    def method_missing(name, *args) 
      @provider.__send__(name, *args)
    end  
    
    def inspect
      YAML.dump(self)
    end
  end
  
  def verify(*argv, &logic)
    Verify.new(*argv, &logic)
  end  
  
  def v(*argv, &logic)
    Verify.new(*argv, &logic)
  end   
end

if $0 == __FILE__
  require 'test/unit'  
  require "yaml"
  
  module Action
    class TestDummy
      attr :timeOut, true
      
      def initialize
        self.timeOut = 2400
      end
      def run
        "hello world"
      end
    end
    # Unit test cases for NoDump
    class NoDumpTest < Test::Unit::TestCase         
      def testBase
        testOne = Action::Verify.new(Action::TestDummy.new) { |caller, x|     
          if( x == "hello world")     
            caller.pass = true  
          else
            caller.pass = true
            caller.message = x 
          end
        }
        assert(testOne.run.pass == true) 
      end      
      
      def testTimeout
        testOne = Action::Verify.new(Action::TestDummy.new, 60) { |caller, x|     
          if( x == "hello world")     
            caller.pass = true  
          else
            caller.pass = true
            caller.message = x 
          end
        }
        puts YAML.dump(testOne)
      end  
      
      def testTimeOutNill
        testOne = Action::Verify.new(nil, nil)
        assert(testOne.timeOut == 120)
        testTwo = Action::Verify.new(23, 'abc')
        assert(testTwo.timeOut == 120)
      end
    
      def testNegative
        testTwo = Action::Verify.new(Action::TestDummy.new) { |caller, x|     
          if( x != "hello world")      
            caller.pass = true 
          else
            caller.pass = false
            caller.message = x
          end          
        }
        result = testTwo.run
        assert(result.pass == false) 
        assert(result.message == "hello world")
      end
      
      def testSuppress
        testOne = Action::Verify.new(Action::TestDummy.new) { |caller, x|     
          if( x != "hello world")      
            caller.pass = true 
          else
            caller.pass = false
            caller.message = x
            caller.suppressDump("Suppressed for unit test")
          end          
        }
        result = testOne.run
        assert(result.pass == false) 
        assert(result.message == "hello world")
        assert(YAML.dump(result) =~ /^provider: Suppressed for unit test$/)
        
        testTwo = Action::Verify.new(Action::TestDummy.new) { |caller, x|     
          if( x != "hello world")      
            caller.pass = true 
          else
            caller.pass = false
            caller.message = x
            caller.suppressDump()
          end          
        }
        result = testTwo.run
        assert(result.pass == false) 
        assert(result.message == "hello world")
        puts result.inspect
        assert(YAML.dump(result) =~ /^provider: skipped, please debug$/)
        
      end      
      
      def testInspect
        testMe = Action::Verify.new(Action::TestDummy.new) {}
        testMe.run
        puts testMe.inspect 
      end
    end
  end
end
 
  

