#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Modified by: gzhang $
# $Author$
#
# Part of the command class structure.  This is the interface to zm*ctl commands
#
if($0 == __FILE__)
  mydata = $:.unshift(File.split(Dir.getwd)[0])   #append library path
end

require 'action/runcommand'
require 'action/stafsystem'
require 'tempfile'
require 'model/testbed'
require 'model'


module Action # :nodoc

  class ZMCbpolicydctl < Action::RunCommandOnMta
  
    #
    #  Create a ZMCbpolicydctl object.
    # 
      
    def initialize(*arguments) 
      super(File.join(ZIMBRAPATH,'bin','zmcbpolicydctl'), ZIMBRAUSER, *arguments)
    end  
  end
  
  class ZMCbpolicydinit < Action::RunCommandOnMta
  
    #
    #  Create a ZMCbpolicydinit object.
    # 
      
    def initialize(*arguments) 
      super(File.join(ZIMBRAPATH,'libexec','zmcbpolicydinit'), ZIMBRAUSER, *arguments)
    end  
  end 
  
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test case for ZMCbpolicydctl object
    class ZMCbpolicydctlTest < Test::Unit::TestCase
      def test_run
        testObject = Action::ZMCbpolicydctl.new('help')
        testObject.run
        assert_equal(1, testObject.exitstatus)
        assert_match(/Usage:\s+#{File.join(Command::ZIMBRAPATH, 'bin', 'zmcbpolicydctl')} start\|stop\|kill\|reload\|restart\|status/, testObject.response)        
      end
    end
    
    #
    # Unit test case for ZMCbpolicydinit object
    class ZMCbpolicydinitTest < Test::Unit::TestCase
      def test_run
        testObject = Action::ZMCbpolicydinit.new('help')
        testObject.run
        assert_equal(0, testObject.exitstatus)
        assert_match(/Usage:\s+#{File.join(Command::ZIMBRAPATH, 'libexec', 'zmcbpolicydinit')} \[-force\]/, testObject.response)        
      end
    end
  end
end


