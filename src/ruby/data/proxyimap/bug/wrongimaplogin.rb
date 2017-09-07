#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug #62000 and #60123 - send wrong login to IMAP and close connection - results in sig 11

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/runcommand"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "socket"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Sig11 on wrong IMAP LOGIN test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)


include Action


#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
                  
  if  Model::TARGETHOST.proxy
    [
     Action::ZMProv.new('mcf', 'zimbraReverseProxyImapStartTlsMode', 'on'),
     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'stop'),
     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'start'),

      v(cb("check") {
        # count number of known sig11 on the log
        occurences = Array.new
        occurences[0] = RunCommand.new('grep', Command::ZIMBRAUSER, '"signal 11"',
                       File.join(Command::ZIMBRAPATH, 'log', 'nginx.log')).run[1].split("\n").size
        
        1000.times do
          begin
            scon = TCPSocket.new(Model::TARGETHOST, Model::IMAP)
            scon.puts "a1 login nonexistinguser anypassword"
            scon.close
          rescue => e
          end
        end
        1000.times do
          begin
            scon = TCPSocket.new(Model::TARGETHOST, Model::IMAP)
            scon.puts "a1 login nonexistinguser anypassword"
            scon.puts "logout"
        
          rescue => e
          end
        end
        
        sleep(30) # wait till all connections will be closed
        
        # number of sig11 in the nginx.log after test run, should be the same
        occurences[1] = RunCommand.new('grep', Command::ZIMBRAUSER, '"signal 11"',
                       File.join(Command::ZIMBRAPATH, 'log', 'nginx.log')).run[1].split("\n").size
        occurences
      }) do |mcaller, data|
        mcaller.pass = data[0] == data[1]
      end
    ]
  end

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
