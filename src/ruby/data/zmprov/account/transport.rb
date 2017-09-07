#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare
#
# zmprov account transport test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/zmprov" 
require "action/verify"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov account mail transport test"

 
include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
timeNow = Time.now.to_i.to_s
mDomain = ZMProv.new('gcf', 'zimbraDefaultDomainName').run[1].split.last
accountOne = Model::User.new("#{name + '1' + timeNow}@#{mDomain}", Model::DEFAULTPASSWORD)
accountTwo = Model::User.new("#{name + '2' + timeNow}@#{mDomain}", Model::DEFAULTPASSWORD)
accountThree = Model::User.new("#{name + '3' + timeNow}@#{mDomain}", Model::DEFAULTPASSWORD)
(mCfg = ConfigParser.new).run
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [

  #If zimbraMailTransport is provided on create, we do not set zimbraMailHost (error if you provide both).
  v(ZMProv.new('ca', accountOne.name, accountOne.password)) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  
  v(ZMProv.new('ga', accountOne.name, 'zimbraMailHost', 'zimbraMailTransport')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   !(transport = data[1][/zimbraMailTransport:\s*(\S+)/, 1]).nil? &&
                   !(host = data[1][/zimbraMailHost:\s*(\S+)/, 1]).nil? &&
                   mCfg.getServersRunning('store').include?(host) &&
                   transport == "lmtp:#{host}:7025"
  end,
  
  v(ZMProv.new('ca', accountTwo.name, accountTwo.password, 'zimbraMailTransport', "lmtp:#{mCfg.getServersRunning('store').first}:7025")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  
  v(ZMProv.new('ga', accountTwo.name, 'zimbraMailHost', 'zimbraMailTransport')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1][/zimbraMailHost:\s*(\S+)/, 1].nil? &&
                   !(transport = data[1][/zimbraMailTransport:\s*(\S+)/, 1]).nil? &&
                   transport =~ /lmtp:(#{mCfg.getServersRunning('store').join('|')}):7025/
  end,
  
  v(ZMProv.new('ca', accountThree.name, accountThree.password,
               'zimbraMailTransport', "lmtp:#{mCfg.getServersRunning('store').first}:7025",
               'zimbraMailHost', mCfg.getServersRunning('store').first)) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /invalid request: setting both zimbraMailHost and zimbraMailTransport in the same request is not allowed/
  end,

=begin
If zimbraMailHost is modified, then see if applying lmtp rule to old
zimbraMailHost value would result in old zimbraMailTransport - if it would, then
replace both zimbraMailHost and set new zimbraMailTransport.  Otherwise error.

case (a)

    zimbraMailHost is mbs1
    zimbraMailTransport is lmtp:mbs1:7025
 
    zmprov ma zimbraMailHost mbs2.example.com

    results in

    zimbraMailHost is now mbs2
    zimbraMailTransport is now lmtp:mbs2:7025

=end
  v(ZMProv.new('ma', accountOne.name, 'zimbraMailHost', 'foo.com')) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /invalid request: specified zimbraMailHost does not correspond to a valid server service hostname: foo.com/
  end,
  
  ZMProv.new('cs', 'test.com'),
  
  v(ZMProv.new('ma', accountOne.name, 'zimbraMailHost', 'test.com')) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /invalid request: specified zimbraMailHost does not correspond to a mailclient server with service webapp enabled: test.com/
  end, 
  
  ZMProv.new('ms', 'test.com', '+zimbraServiceEnabled', 'mailbox'),

  v(ZMProv.new('ma', accountOne.name, 'zimbraMailHost', 'test.com')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^$/
  end,

  v(ZMProv.new('ga', accountOne.name, 'zimbraMailHost', 'zimbraMailTransport')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   !(transport = data[1][/zimbraMailTransport:\s*(\S+)/, 1]).nil? &&
                   !(host = data[1][/zimbraMailHost:\s*(\S+)/, 1]).nil? &&
                   host == 'test.com' &&
                   transport == "lmtp:#{host}:7025"
  end,

=begin
  case (b)

    zimbraMailHost is set
    zimbraMailTransport is smtp:relay1

    zmprov ma zimbraMailHost mbs2 -> error because this would stomp mail transport
    zmprov ma zimbraMailTransport smtp:relay2 -> OK, allowed
    zmprov ma zimbraMailHost mbs2 zimbraMailTransport smtp:relay2 -> error
(never allowed)
=end
  v(ZMProv.new('ma', accountTwo.name, 'zimbraMailHost', mCfg.getServersRunning('store').first)) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^$/
  end,
  
  v(ZMProv.new('ma', accountTwo.name, 'zimbraMailTransport', 'smtp:relay.com')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^$/
  end,

  v(ZMProv.new('ga', accountTwo.name, 'zimbraMailHost', 'zimbraMailTransport')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1][/zimbraMailHost:\s*(\S+)/, 1] == mCfg.getServersRunning('store').first &&
                   data[1][/zimbraMailTransport:\s*(\S+)/, 1] == 'smtp:relay.com'
  end,
  
  v(ZMProv.new('ma', accountTwo.name, 'zimbraMailHost', mCfg.getServersRunning('store').first)) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /invalid request: current value of zimbraMailHost does not match zimbraMailTransport, computed mail transport from current zimbraMailHost=lmtp:#{mCfg.getServersRunning('store').first}:7025, current zimbraMailTransport=smtp:relay.com/
  end,

  v(ZMProv.new('ma', accountTwo.name, 
               'zimbraMailTransport', 'smtp:relay.com',
               'zimbraMailHost', mCfg.getServersRunning('store').first)) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /invalid request: setting both zimbraMailHost and zimbraMailTransport in the same request is not allowed/
  end,
  
  ZMProv.new('ms', 'test.com', '-zimbraServiceEnabled', 'mailbox'),

]
#
# Tear Down
#
current.teardown = [
  cb("delete account", 120) do
    DeleteAccount.new(accountOne).run
  end,
  DeleteAccount.new(accountTwo),
  DeleteAccount.new(accountThree),
  ZMProv.new('ds', 'test.com'),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end