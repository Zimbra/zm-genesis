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
# Part of the command class structure.  This implement switching in and out of zimbra user
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end 
  
require 'action/cuid'
require 'action/proxy'
 
module Action # :nodoc
  #
  #  Perform switching to zimbra user
  #
  class ZimbraUser < Action::CUid
    #
    # Objection creation
    #  
    def initialize()
      super(ZIMBRAUSER) 
      @proxy = nil    
    end
    
    #
    # Produce delay action proxy that revert to previous user uid
    #
    def revert()
      if(@proxy == nil)
        @proxy = Action::Proxy.new(self.method('revert'))
      end
      @proxy
    end    
    
    def run()
      super()     
    end 
    
    def to_str
      "Action:ZimbraUser name:#{@userName}"
    end  
  end
    
  
end

if $0 == __FILE__
  require 'test/unit'  
  
  module Action
    # Unit test cases for ZimbraUser
    class ZimbraUserTest < Test::Unit::TestCase     
      def testRun 
        testObject = Action::ZimbraUser.new  
        testObject.revert 
      end
      
      def testTOS
        testObject = Action::ZimbraUser.new
        puts testObject
      end
    end
  end
end
 
  

