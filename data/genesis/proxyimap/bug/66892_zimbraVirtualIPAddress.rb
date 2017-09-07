#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug # 66892 -zmproxyconfgen create conf files with bad IP (in split DNS setup)
# Fix - zmproxyconfgen should use value of zimbraVirtualIPAddress if possible
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
require "action/zmprov"
require "action/zmamavisd"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'yaml'


include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmproxyconfgen should use zimbraVirtualIPAddress"

# Check the presence of /etc/hosts
etcHosts = (RunCommand.new('ls', 'root', '/etc/hosts').exitstatus == 0)

fakeDomain = 'zimbraVirtualIPAddress'+Time.now.to_i.to_s+'.com'
fakeHost = "\"1.2.3.55 mail.#{fakeDomain}\""
confPath = File.join(Command::ZIMBRAPATH, 'conf/nginx/includes/nginx.conf.web.http')
#
# Setup
#
current.setup = [
  
]

# Execution
#
current.action = [  
    
  #test is to be executed only if nginx is on and system has /etc/hosts
  if (Model::TARGETHOST.proxy && etcHosts)
  [
    # should be TRUE by default anyway
    ZMProv.new('mcf', 'zimbraReverseProxyGenConfigPerVirtualHostname', 'TRUE'),
    
    # add fake host to /etc/hosts
    v(RunCommand.new( 'sed', 'root', "-i.bak \"$ s/^\\(.*\\)$/\\1\\\\`echo -e '\\n#{fakeHost}'`/\" /etc/hosts"  )) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
      
    # Config should be generated with value from zimbraVirtualIPAddress
    ZMProv.new("cd #{fakeDomain} zimbraVirtualHostName mail.#{fakeDomain} zimbraVirtualIPAddress 1.2.3.4"),
    
    v(ZMControl.new('restart', 120)) do | mcaller, data |
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
  
    v(RunCommand.new('grep', 'root', '1.2.3.4', confPath)) do | mcaller, data |
      mcaller.pass = data[1].include?('1.2.3.4')
    end,
    
    # Nginx should not start if number of virtual IP is not equal number of hosts
    ZMProv.new("md #{fakeDomain} +zimbraVirtualIPAddress 1.2.3.5"),

    v(RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'restart')) do | mcaller, data |
      mcaller.pass = data[0] == 1 &&
		     data[1].include?("The configurations of zimbraVirtualHostname and zimbraVirtualIPAddress are mismatched")
    end,
    
    # clean up
    ZMProv.new('dd', fakeDomain),
    
    v(cb("Revert /etc/hosts/ and restart", 120) do
      RunCommand.new('mv', 'root', '/etc/hosts.bak /etc/hosts').run
      ZMProxyctl.new('restart').run
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



