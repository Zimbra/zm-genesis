#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug 54439 nginx is failing on signal 11 with when memcache hostname 
# can map to more than one IP (for example, a normal IP and 127.0.1.1 set by Ubuntu)
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
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'yaml'


include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Bug 54439. Duplicate hostname and proxy"

dupHost = "127.0.1.1 #{Model::TARGETHOST} #{Model::TARGETHOST.name}"

# Check the presence of /etc/hosts
etcHosts = (RunCommand.new('ls', 'root', '/etc/hosts').exitstatus == 0)

#
# Setup
#
current.setup = [
  
]


# Execution
#
current.action = [  
    
	# test is to be executed only if nginx is on and system has /etc/hosts
	if (Model::TARGETHOST.proxy && etcHosts)
	[
	cb("Modify /etc/hosts"){
	  # create a backup copy of /etc/hosts
	  RunCommand.new('cp', 'root', '/etc/hosts /var/tmp/hosts.copy').run[1]

    #add duplicated host name to loopback interface 127.0.1.1
    RunCommand.new('echo' , 'root', "#{dupHost} >> /etc/hosts").run[1]
	},
	
  v(ZMControl.new('restart', 120)) do | mcaller, data |
      mcaller.pass = (data[0] == 0) && !data[1].include?('failed')
  end,

	# The most visible error behaviour is nginx.log getting flooded with signal 11
	v(RunCommand.new('tail', 'root', '-n15', File.join(Command::ZIMBRAPATH, 'log', 'nginx.log'))) do | mcaller, data |
	  mcaller.pass = !data[1].include?('signal 11')
	end,

  v(cb("Revert /etc/hosts/ and restart", 120) do
    RunCommand.new('mv', 'root', '/var/tmp/hosts.copy /etc/hosts').run
    ZMControl.new('restart').run
	end) do | mcaller,data |
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
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

