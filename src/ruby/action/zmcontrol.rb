#!/usr/bin/ruby -w
#
# = action/getbuild.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure.  This is the interface to zmcontrol command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'action/system'
require 'action/stafsystem'
require 'model/testbed'
require 'net/imap'
 
 
module Action # :nodoc

  #
  # Perform tomcat action.  This will invoke some tomcat with some argument
  # from http server
  #
  class ZMControl < Action::Command
  
    #
    #  Create a ZMControl object.
    # 
    attr :response, true
    
    def initialize(*arguments) 
      super()
      self.timeOut = 600
      @zmcontrolpro = File.join(ZIMBRAPATH,'bin','zmcontrol')
      host = Model::TARGETHOST
      host = arguments.pop if arguments.last.instance_of?(Model::Host)
      if(host.to_s == Model::TARGETHOST.to_s)
        @runner = System.new(File.join('','usr','bin','perl'), ZIMBRAUSER, @zmcontrolpro, *arguments)
      else 
        @runner = StafSystem.new(host, File.join('','usr','bin','perl'), ZIMBRAUSER, @zmcontrolpro, *arguments)
      end 
    end 
        
    def run
      begin
        @response = @runner.run       
      rescue Net::IMAP::ByeResponseError
      end
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
    # Unit test case for ZMControl object
    class ZMControlTest < Test::Unit::TestCase
      def testRun
        testObject = Action::ZMControl.new('status')
        testObject.run 
        puts testObject.response
      end
      
      def testTOS
        testObject = Action::ZMControl.new
        puts testObject
      end
      
      def testTimeOut
          testObject = Action::ZMControl.new
          assert(testObject.timeOut == 180)
      end
    end
  end
end


