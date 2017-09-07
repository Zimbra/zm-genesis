#!/usr/bin/ruby -w
#
# = action/command.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# This is the command structure for the test framework
# 
require 'yaml'

module Action # :nodoc

  #
  # Base class for all the command object
  #
  class Command 
    attr :timeOut, true
    attr :check, true
    
    @@run_env = Hash.new()
    
    CONFIG = 'config_file'
    MAILPORT = 'mailport'
    NAMESPACE = 'namespace'
    TESTCASE = 'testcase'
    TOKEN='authToken'
    SESSIONID= 'sessionId'
    ZIMBRAPATH = '/opt/zimbra'
    ZIMBRATMPPATH = File.join(ZIMBRAPATH, 'data', 'tmp')
    ZIMBRAUSER = 'zimbra'
    ZIMBRACOMMON = File.join(ZIMBRAPATH, 'common')

    
    # Initialize global symbol table
    def initialize
      @timeOut = 60 #default timeout per action is 1 minute
      self.check = false
    end
    #
    # Run the particular command
    def run
    end        
        
    def inspect
      YAML.dump(self)
    end
    
    def Command.run_env
      @@run_env
    end
  end
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class CommandTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = Command.new
        assert(testOne.timeOut == 60)
        testOne.timeOut = 70
        assert(testOne.timeOut == 70)
       
      end
      
    end
   
end
 
  

