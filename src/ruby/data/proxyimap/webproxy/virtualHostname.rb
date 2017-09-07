#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug #69648, 69650
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
require "action/zmlocalconfig"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'yaml'


include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "multiple zimbraVirtualHostname"

# Check the presence of /etc/hosts
etcHosts = (RunCommand.new('ls', 'root', '/etc/hosts').exitstatus == 0)

# are we running these tests today?
runIt = rand(4) == 0 ? true : false

if runIt && etcHosts
  # settings for 1 domain - many virtual hosts
  fakeDomain = File.basename(__FILE__,'.rb') + Time.now.to_i.to_s + '.com'
  fakeHost = ['"\$a\\']
  for i in (1..1000)
    fakeHost.push("1.2.3.55 test#{i.to_s}.#{fakeDomain}\\\\n")
    RunCommand.new('echo', 'root', "md #{fakeDomain} +zimbraVirtualHostname test#{i.to_s}.#{fakeDomain} >> /tmp/#{fakeDomain}.dat").run
  end
  fakeHost.push('"')
  
  # settings for many domains with one virtual host
  seedDomain = 'm' +File.basename(__FILE__,'.rb') + Time.now.to_i.to_s + '.com'
  virtualHosts = ['"']
  for i in (1..1000)
    mDomain = seedDomain.sub(/^m/, "m#{i.to_s}")
    RunCommand.new('echo', 'root', "cd #{mDomain} zimbraVirtualHostname test.#{mDomain} >> /tmp/#{seedDomain}.dat").run
    RunCommand.new('echo', 'root', "dd #{mDomain} >> /tmp/#{seedDomain}.delete").run
  
    virtualHosts.push("1.2.3.66 test.#{mDomain}\\\\n")
  end
  virtualHosts.push('"')
  
  RunCommand.new('echo', 'root', "#{(fakeHost + virtualHosts).join} >> /tmp/#{fakeDomain}.etc").run
  confPath = File.join(Command::ZIMBRAPATH, 'conf/nginx/includes/nginx.conf.web.http')
end
#
# Setup
#
current.setup = [
  
]

# Execution
#
current.action = [  
    
  #test is to be executed only if nginx is on and system has /etc/hosts
  if runIt && Model::TARGETHOST.proxy && etcHosts
  [
    # should be TRUE by default anyway
    ZMProv.new('mcf', 'zimbraReverseProxyGenConfigPerVirtualHostname', 'TRUE'),
    
    # populate /etc/hosts
    v(RunCommand.new( 'sed', 'root', "-i.bak -f /tmp/#{fakeDomain}.etc /etc/hosts")) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
 
    # create domain with many virtual hosts
    v(ZMProv.new("cd #{fakeDomain}")) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
    v(ZMProv.new("-f", "/tmp/#{fakeDomain}.dat")) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
    v(ZMProv.new("-f", "/tmp/#{seedDomain}.dat")) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
    
    # modify proxy hash settings
    ZMLocalconfig.new('-e', 'proxy_server_names_hash_max_size=3000'),
    ZMLocalconfig.new('-e', 'proxy_server_names_hash_bucket_size=128'),
    
    # server should restart
    v(ZMControl.new('restart', 360)) do | mcaller, data |
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    # nginx config files should contain all virtual hosts
    v(RunCommand.new('grep', 'root',"test1000.#{fakeDomain}", confPath)) do | mcaller, data |
      mcaller.pass = data[1].include?("test1000.#{fakeDomain}")
    end,
    v(RunCommand.new('grep', 'root', "test.#{seedDomain.sub(/^m/, 'm1000')}", confPath)) do | mcaller, data |
      mcaller.pass = data[1].include?("test.#{seedDomain.sub(/^m/, 'm1000')}")
    end,
    
    # No config should be generated
    ZMProv.new('mcf', 'zimbraReverseProxyGenConfigPerVirtualHostname', 'FALSE'),
    v(RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'restart')) do | mcaller, data |
      mcaller.pass = data[0] == 0
    end,
    v(RunCommand.new('grep', 'root',"test1000.#{fakeDomain}", confPath)) do | mcaller, data |
      mcaller.pass = !data[1].include?("test1000.#{fakeDomain}")
    end,
    v(RunCommand.new('grep', 'root', "test.#{seedDomain.sub(/^m/, 'm1000')}", confPath)) do | mcaller, data |
      mcaller.pass = !data[1].include?("test.#{seedDomain.sub(/^m/, 'm1000')}")
    end,

    # clean up
    ZMProv.new('mcf', 'zimbraReverseProxyGenConfigPerVirtualHostname', 'TRUE'),
    
    cb("delete domains", 360) do
      ZMProv.new('dd', fakeDomain).run
      ZMProv.new("-f", "/tmp/#{seedDomain}.delete").run
    end,
    
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



