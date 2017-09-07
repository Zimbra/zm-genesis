#!/usr/bin/ruby -w
#
# = action/zmrestoreoffline.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmrestore command
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
  class ZMRestoreOffline < Action::Command
  
    #
    #  Create a ZMRestoreOffline object.
    #
    attr :response, true

    def initialize(*arguments)
      super()
      @runner = RunCommandOnMailbox.new(File.join(ZIMBRAPATH,'bin','zmrestoreoffline'), ZIMBRAUSER, '-d', *arguments)       
      @label = ''
      self.timeOut = 2400 #timeout to 40 minutes
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
    # Unit test case for ZMRestoreOffline object
    class ZMRestoreOfflineTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMRestoreOffline.new
        testObject.run 
        assert(testObject.response[1].include?('tomcat'), "fail path")
      end
      
      def testTOS
        testObject = Action::ZMRestoreOffline.new('ca yes')
        puts testObject
      end
    end
  end
end


 