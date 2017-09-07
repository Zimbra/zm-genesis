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
  class Decorator  < Action::Command
    attr :object, true
    
    NODUMP = "nodump"
    #
    # Objection creation
    # create method wrapper
    def initialize(object = nil, *argv)
      super()
      @object = object
      argv.each { |x|
        self.class.send(:define_method ,x.to_sym) {true}
      }
    end     
        
    def inspect
      YAML.dump(self)
    end
    
    def method(mysym)
      @object.method(mysym)
    end
        
    def method_missing(name, *args) 
      @object.__send__(name, *args)
    end
  end
  
  def decorator(*argv)
    Decorator.new(*argv)
  end  
  
  def d(*argv)
    Decorator.new(*argv)
  end  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for NoDump
    class NoDumpTest < Test::Unit::TestCase         
      def testInitialize
        testOne = Action::Decorator.new("sowhat", "nodump")
        assert(true == testOne.respond_to?(:nodump), "decorator test") 
        assert(6 == testOne.length, "decorate test")
      end      
    end
  end
end
 
  

