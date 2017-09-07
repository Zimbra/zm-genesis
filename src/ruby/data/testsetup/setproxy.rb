#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Set up for imap proxy testing
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/command"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmcontrol"
require 'action/tcpdump'
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'yaml'


include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Set up for imap proxy"



#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [  
  cb("Proxy Detection") {
    checkProxy = RunCommand.new('zmprov', Command::ZIMBRAUSER, "gs #{Model::TARGETHOST} zimbraServiceEnabled").run[1] rescue []
    # Check to see if it is running proxy mode 
    Model::TARGETHOST.proxy = checkProxy.split(/\n/).any? {|x| x =~/proxy/ }   
    if(Model::TARGETHOST.proxy) #Set monitor if necessary
      #push TCPDump monitor by default it monitors port 7143 of the loopback interface on the localhost
      dump_object = Action::TCPDump.new
      if([1, 9, 39].any? {|x| x == Model::TARGETHOST.architecture })
        dump_object.set(:port => 7143, :os => :osx)
      else
        dump_object.set(:port => 7143, :os => :unix)
      end
      #current.monitor.push dump_object
    end
  },
  
  cb("Change behavior if necessary") {
    if(Model::TARGETHOST.proxy)     
      Action::IMAP.badString = "invalid command"
      CapabilityVerify.removeCapability("LOGIN-REFERRALS", "AUTH=X-ZIMBRA")
    end
  }
  
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
