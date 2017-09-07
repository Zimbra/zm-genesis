#!/usr/bin/ruby -w
#
# = action/waitqueue.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# This action wait till the mail queue to be empty
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?noitca/,"").reverse;$:.unshift(mydata);
end
require 'model/testbed'
require 'model/servers'

require 'action/command'
require 'action/runcommand'
require 'action/system'
require 'action/stafsystem'

require 'timeout'
require 'yaml'
 
module Action # :nodoc
  #
  #  Perform proxy wrapping on some method
  #
  class WaitQueue < Action::Command
    #
    # Objection creation
    # create method wrapper
    def initialize(timeOut = 1200, host = nil)
      super()
      self.timeOut = timeOut
      @mta = Array.new
      
      if host.nil?
        mta_nodes = Model::Servers.getServersRunning("mta")
        mta_nodes.each do |node|
          @mta += [Model::Host.new(node)]
        end
      else
        @mta[0] = Model::Host.new(host.to_s)
      end
        
    end
    
    def run
      result = nil
      
      begin
        Timeout::timeout(self.timeOut - 4) do
          hasMail = true
          
          begin
            Kernel.sleep(5)
            result = !@mta.any? do |mta|
              !RunCommand.new(File.join(ZIMBRACOMMON,'sbin','postqueue'), ZIMBRAUSER, '-p', mta).run[1].include?('Mail queue is empty')
            end
            if result
              hasMail = false
            else
              @mta.each { |mta| RunCommand.new(File.join(ZIMBRACOMMON,'sbin','postqueue'), ZIMBRAUSER, '-f', mta).run }
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
    class WaitQueueTest < Test::Unit::TestCase         
      def testBase
        testOne = Action::WaitQueue.new 
        assert((testOne.run)[1].include?('empty'))      
      end      
      
      def testTimeOut
        testOne = Action::WaitQueue.new(30)
        assert(testOne.timeOut == 30) 
        testTwo = Action::WaitQueue.new
        assert(testTwo.timeOut == 1200)     
      end        
    end
  end
end
 
  

