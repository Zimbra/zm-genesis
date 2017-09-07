#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# This action wait till /opt/zimbra/store/incoming folder is empty
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'action/runcommand'
require 'action/system'
require 'action/stafsystem'
require 'model/testbed'
require 'model/servers'
require 'timeout'
require 'yaml'

 
module Action # :nodoc
  
  #
  #  Perform proxy wrapping on some method
  #
  class WaitIncoming < Action::Command
    #
    def initialize(timeOut = 1000, host = nil)
      super()
      self.timeOut = timeOut
      @store = Array.new
      
      if host.nil?
        store_nodes = Model::Servers.getServersRunning("mailbox")
        store_nodes.each do |node|
          @store += [Model::Host.new(node)]
        end
      else
        @store[0] = Model::Host.new(host.to_s)
      end
    end
      
      
    # Wait till /opt/zimbra/store/incoming folder is not empty
    def run
      result = nil
      
      begin
        Timeout::timeout(self.timeOut - 4) do
          hasMail = true
          
          begin
            Kernel.sleep(5)
            result = !@store.any? do |store|
              RunCommand.new('ls', ZIMBRAUSER,  '-A', File.join(ZIMBRAPATH,'store','incoming'), store).run[1].include?('.msg')
            end
            if result
              hasMail = false
            end
          end while(hasMail)
        end
      rescue => e
        result = e
      end
      [0, result]
      
    end
    
   
    def to_str
      @runner.to_str
    end 
            
    def method_missing(name, *args) 
      @runner.__send__(name, *args)
    end  
    
    def inspect
      YAML.dump(self)
    end
  end  
   
end

if $0 == __FILE__
  require 'test/unit'  
  require "yaml"
  
  module Action 
    # Unit test cases for NoDump
    class WaitIncomingTest < Test::Unit::TestCase         
      def testBase
        testOne = Action::WaitIncoming.new 
        assert((testOne.run)[1])      
      end  
      
      def testTimeOut
        testOne = Action::WaitIncomingTest.new(30)
        assert(testOne.timeOut == 30) 
        testTwo = Action::WaitIncoming.new
        assert(testTwo.timeOut == 1200)     
      end        
               
    end
  end
end
 
  

