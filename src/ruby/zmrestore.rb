#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#
# Part of the command class structure.  This is the interface to zmrestore command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'model/testbed'
 
 
module Action # :nodoc

  #
  # Perform zmrestore action.  This will invoke zmrestore with some arguments 
  #
  class ZMRestore < Action::Command
  
    #
    #  Create a ZMRestore object.
    #      
    def initialize(*arguments)
      super()   
      myarguments = arguments   
      self.timeOut = 2400 #timeout to 40 minutes
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmrestore'), ZIMBRAUSER,  '-d', *myarguments)  
    end
    
    def run
      @runner.run
    end    
    
    def method_missing(name, *args) 
      @runner.__send__(name, *args)
    end    
  end 
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMRestore object
    class ZMRestoreTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMRestore.new('-a', Model::TARGETHOST.cUser('test1'))
        testObject.run 
        assert(testObject.exitstatus == 0, "Error in restore")
      end
      
      def testTOS
        testObject = Action::ZMRestore.new('ca yes')
        assert(testObject.to_str.include?("ca yes"), "to s failure")
      end
      def testTimeOut
        testObject = Action::ZMRestore.new
        assert(testObject.timeOut == 2400)
      end
    end
  end
end


 