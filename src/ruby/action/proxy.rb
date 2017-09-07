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
# Part of the command class structure. Proxy class binds to particular method so
# method invocation can be delayed until needed
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/command'
 
module Action # :nodoc
  #
  #  Perform proxy wrapping on some method
  #
  class Proxy < Action::Command
    #
    # Objection creation
    # create method wrapper
    def initialize(method = nil, *args, &myblock)
      super()        
      @method = method     
      @args = args  
      @response = nil
      if block_given? then
        @myblock = myblock
      else
        @myblock = nil
      end
    end
     
    #
    # Execute proxy action
    #  
    def run 
      super()
      return unless @method
      #if method is a string, do a lookup
      if @method.class == Method
        runMethod = @method
        runArgs = @args
      else
        runMethod = @method.method(@args.first)
        runArgs = @args[1..-1]
        
      end
      begin
        if(@myblock != nil) then
          @response = runMethod.call(*runArgs, &@myblock)
        else
          @response = runMethod.call(*runArgs)
        end          
      rescue => mexception
        @response = mexception
      end
      @response
    end   
    
    def response
      return @response
    end    
    
    def response=(val)
      @response = val
      @response
    end   
    
    def to_str
      "Action:Proxy method #{@method} #{@args}"
    end  
  end  
  
  def proxy(*argv)
    Proxy.new(*argv)
  end  
  
  def p(*argv)
    Proxy.new(*argv)
  end
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for Proxy
    class ProxyTest < Test::Unit::TestCase     
      def testNoArgument 
        testOne = Action::Proxy.new('hello world')
        assert(testOne.run == 'hello world',"no argument test")  
      end
      
      def testOneArgument
        testString = "yes dear"
        testTwo = Action::Proxy.new(testString.method('rindex'),'e')        
        assert((testTwo.run == 5), 'one argument test')
      end
      
      def testBlock
        testThree = Action::Proxy.new(1.method('upto'), 5) { |i | puts i }
        testThree.run
      end
      
      def testTOS
        require 'model/testcase'
        testObject = Action::Proxy.new(Model::TestCase.instance.method('defaultSetup'))
        puts testObject
        require "yaml"
        puts YAML.dump(testObject)
      end
    end
  end
end
 
  

