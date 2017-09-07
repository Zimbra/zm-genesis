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
# Part of the command class structure.  This is the interface to tomcat command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/system'
require 'action/stafsystem' 
require 'model/testbed'
 
 
module Action # :nodoc

  #
  # Perform tomcat action.  This will invoke some tomcat with some argument
  # from http server
  #
  class Tomcat < Action::Command
  
    attr_writer :response
    #
    #  Create a tomcat object.
    # 
    
    def initialize(*arguments) 
      super()
      if(Model::TARGETHOST == Model::CLIENTHOST)
        @runner = System.new(File.join(ZIMBRAPATH,'bin','tomcat'), ZIMBRAUSER, *arguments)
      else 
        @runner = StafSystem.new(Model::TARGETHOST, File.join(ZIMBRAPATH,'bin','tomcat'), ZIMBRAUSER, *arguments)
      end       
    end 
    
    def run
      begin
        @response = @runner.run       
      rescue Net::IMAP::ByeResponseError 
        #This is to handle IMAP sub system library issue
        #Any active connection will throw an exception when server restart        
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
    # Unit test case for tomcat object
    class TomcatTest < Test::Unit::TestCase
      def testRun
        testObject = Action::Tomcat.new('restart')
        testObject.run
        #puts YAML.dump(testObject.response)
        assert(testObject.response.include?("shutdown ok"), "fail path")
      end
      
      def testTOS
        testObject = Action::Tomcat.new
        puts testObject
      end
    end
  end
end


