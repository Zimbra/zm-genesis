#!/usr/bin/ruby -w
#
# = action/untar.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Part of the command class structure. Block method binds to particular block
#
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
  class Block < Action::Command
    #
    # Objection creation
    # create method wrapper
     
    def initialize(*argv, &b)
      super()        
      @description = ""
      if(argv.size > 0)
        @description = argv[0]
      end
      if(argv.size > 1)
        self.timeOut = argv[1]
      end
      @b = b      
      @response = nil
        
    end
     
    #
    # Execute proxy action
    #  
    def run  
      return if (@b == nil)
      super
      begin
        @response = @b.call
      rescue => error
        puts error if $DEBUG
        puts error.backtrace if $DEBUG 
        @response = error
      end
      @response
    end   
    
    def response
      return @response
    end       
    
    def to_str
      "Action:Block #{@description}"
    end  
  end  
  
  def cb(*argv, &b)
    Block.new(*argv, &b)
  end  
end

if $0 == __FILE__
  require 'test/unit'  
  include Action
  
   
    # Unit test cases for Proxy
    class BlockTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = cb("hello world") { puts "hello world"
        "hello world"}
        assert(testOne.timeOut == 60)
        assert(testOne.run == 'hello world',"no argument test")  
      end
      
      def testTimer
        testOne = cb("hello world", 600) { puts "hello world"
        "hello world"}        
        assert(testOne.timeOut == 600)
        assert(testOne.run == 'hello world',"no argument test")  
      end
     
      def testTOS
        testOne = cb("hello world") { puts "hello world" 
                                     "hello world"}
        puts testOne.to_str 
      end
    end
   
end
 
  

