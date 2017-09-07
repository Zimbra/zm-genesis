#!/usr/bin/ruby -w
#
# action/simpleconnect.rb
#
# Copyright (c) 2011 zimbra
#
# Written & maintained by Alex Filatau
#
#
# Part of the command class structure.
# Allows to send data to arbitrary port and return unprocessed response
# Does not support SSL connections for now
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require 'net/telnet'
require 'model/testbed'
 
 
module Action # :nodoc

  class SimpleConnect
  
    attr :response

    #
    #  Create a simple telnet connection to a host:port.
    # 
    
    def initialize(host, port, waittime = 2.0, prompt = /.*/, *arguments) 
      @host = host 
      @port = port
      @waittime = waittime
      @prompt = /.*/
      
      @connection = Net::Telnet::new('Host' => host,
                             'Port' => port,
                             'Waittime' => waittime,
                             'Prompt' => prompt,
                             'Telnetmode' => false)
      # just initialized connection will contain server greating
      @response = @connection.waitfor(/.*/)
    end 
    
    #
    # Send arbitrary data to connection
    #
    
    def send_str(*args)
      args.each do |str|
        begin
          @connection.cmd(str) { |r| @response = r}
        rescue Exception => e
          @response = e.message
        rescue Timeout::Error => e
          @response = e.message 
        end
      end
      return self
    end
     
    def run
      return @response
    end

  end 
   
end

if $0 == __FILE__
  require 'test/unit'
  module Action
    #
    # Unit test cases for SimpleConnection object
    class SimpleConnectTest < Test::Unit::TestCase
      def testNew
        testObject = Action::SimpleConnect.new('localhost', 22)
        
        assert(testObject.response.include?("SSH"))
      end
      def testSendStr
        testObject = Action::SimpleConnect.new('localhost', 22)
        testObject.send_str("Some Junk")
        assert(testObject.response.include?("Protocol mismatch"))
      end
    end
  end
end



