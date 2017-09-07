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
# Part of the command class structure.  This is the interface to zmbackup command
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
require 'action/system'
require 'action/stafsystem'
require 'model/testbed'
 
 
module Action # :nodoc

  #
  # Perform zmbackupquery action.  This will invoke some zmbackupabort with some argument 
  #
  class ZMBackupQuery < Action::Command
  
    #
    #  Create a ZMBackupAbort object.
    #
     attr :response, true
    
    def initialize(*arguments)
      super()
      if(Model::TARGETHOST == Model::CLIENTHOST)
        @runner = System.new(File.join(ZIMBRAPATH,'bin','zmbackupquery'), ZIMBRAUSER, '-d', *arguments)
      else 
        @runner = StafSystem.new(Model::TARGETHOST, File.join(ZIMBRAPATH,'bin','zmbackupquery'), ZIMBRAUSER, '-d', *arguments)
      end             
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
    # Unit test case for ZMBackupAbort object
    class ZMBackupQueryTest < Test::Unit::TestCase
      def testRun
        require 'model/testbed'
        
        testObject = Action::ZMBackupQuery.new      
        assert(testObject.response[1] =~ /./, "fail path")
      end
      
      def testTOS
        testObject = Action::ZMBackupQuery.new('ca yes')
        puts testObject
      end
    end
  end
end


 