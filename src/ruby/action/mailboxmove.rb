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
# Part of the command class structure.
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
require 'action/runcommand'    
 
module Action # :nodoc 
  #
  # Perform zmbackup action.  This will invoke some zmbackup with some argument
  # from http server
  #
  class MailMove < Action::RunCommandOnMailbox
  
    #
    #  Create a ZMBackup object.
    # 
    def initialize(*arguments)
      super(File.join(ZIMBRAPATH,'bin','zmmailboxmove'), ZIMBRAUSER, *arguments)       
    end
    
    def run
      @runner.run
    end
    
    def to_str
      @runner.to_str
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
    # Unit test case for ZMBackup object
    class MailMovedTest < Test::Unit::TestCase    
      def testRun         
        testObject = Action::MailMove.new('-h')
        puts YAML.dump(testObject)
        assert(testObject.exitstatus == 0)
      end 
    end
  end
end


 