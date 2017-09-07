#!/usr/bin/ruby
#
# = pop/setup.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# ZMVolume basic test
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov"
require "action/verify"
require 'action/tcpdump'

include Action

current = Model::TestCase.instance()
current.description = "POP Enable Cleartext Login" 
 
  

#
# Global variable declaration
#

# Monitor
# if Model::TARGETHOST.proxy
#   # Get rid of the old tcpdump and insert the new one
#   current.monitor.pop if(Action::TCPDump === current.monitor[-1])
#   dump_object = Action::TCPDump.new
#   if([1, 9, 39].include?(Model::TARGETHOST.architecture))
#     dump_object.set(:os => :osx, :port => 7110)
#   else
#     dump_object.set(:ox => :unix, :unix => 7110)
#   end
#   current.monitor.push dump_object
# end

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [   
                  if Model::TARGETHOST.proxy      
                    [
                     Action::ZMProv.new('mcf', 'zimbraReverseProxyPop3StartTlsMode', 'on'),
                     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'stop'),
                     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'start'),
                     cb("sleep 10") { sleep 10 }, #avoid race condition http://bugzilla.zimbra.com/show_bug.cgi?id=56004
                     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'stop'),
                     Action::RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'start'),
                    ]
                  else 
                    Action::ZMProv.new('ms', Model::TARGETHOST, 'zimbraPop3CleartextLoginEnabled', 'TRUE')  
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
