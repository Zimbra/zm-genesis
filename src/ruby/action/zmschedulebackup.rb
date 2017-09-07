#!/usr/bin/ruby -w
#
# = action/zmschedulebackup.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmschedulebackup command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'tempfile'
require 'model/testbed'

module Action # :nodoc

  #
  # Perform zmrestoreoffline action.  This will invoke zmrestoreoffline with some arguments 
  #
  class ZMScheduleBackup < Action::Command
  
    #
    #  Create a ZMRestoreOffline object.
    #
    attr :response, true
 
    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmschedulebackup'), ZIMBRAUSER, *arguments)   
    end
    
    def run
      @response = @runner.run
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
    # Unit test case for ZMScheduleBackup object
    class ZMScheduleBackupTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMScheduleBackup.new
        testObject.run 
        assert(testObject.response[1].include?('Schedule'), "fail path")
      end
      
      def testTOS
        testObject = Action::ZMScheduleBackup.new
        assert(testObject.class == Action::ZMScheduleBackup)
      end
    end
  end
end


 