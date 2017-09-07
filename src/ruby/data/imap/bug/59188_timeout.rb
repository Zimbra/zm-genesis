#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Bug #59188. Missing timeout on waiting for SSL handshake.


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'socket' 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Bug #59188. Missing timeout while waiting for SSL handshake"

portimaps = 995
portpop3s = 993

include Action

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
                  
                  # open simple connection to IMAPS and wait more then 1 minute
                  # not initiating SSL handshake

                  v(cb("Wait for timeout IMAPS") do
                      scon = TCPSocket.new(Model::TARGETHOST, portimaps)
                      sleep(61)
                      scon.puts "Test MESSAGE"
                    end ) do |mcaller, data|
                      mcaller.pass = data.class == Errno::EPIPE
                  end,
                  
                  # open simple connection to POP3S and wait more then 1 minute
                  # not initiating SSL handshake

                  v(cb("Wait for timeout PO3S") do
                      scon = TCPSocket.new(Model::TARGETHOST, portpop3s)
                      sleep(61)
                      scon.puts "Test MESSAGE"
                    end ) do |mcaller, data|
                      mcaller.pass = data.class == Errno::EPIPE
                  end,
]

#
# Tear Down
#
current.teardown = [

]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end


