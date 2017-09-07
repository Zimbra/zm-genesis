#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug #64033 imap: memcached uid cache: imap client hanging and connection leak if memcachd is down
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP client hangs if memcached is down"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action
#Net::IMAP.debug = true
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [   
  proxy(mimap1.method('login'),testAccount.name,testAccount.password),
  proxy(mimap1.method('select'),"INBOX") , 
  
  RunCommand.new('zmmemcachedctl', 'zimbra', 'stop'),
  
  proxy(mimap2.method('login'),testAccount.name,testAccount.password),
  proxy(mimap2.method('select'),"INBOX"),
  proxy(mimap2.method('logout')),
  proxy(mimap2.method('disconnect')),
  
  proxy(mimap2.method('login'),testAccount.name,testAccount.password),
  proxy(mimap2.method('select'),"INBOX"),
  proxy(mimap2.method('logout')),
  proxy(mimap2.method('disconnect')),
  
  ## TODO - use log checker
  v(RunCommand.new('tail', 'root', '-n35', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))) do | mcaller, data |
     mcaller.pass = !data[1].include?('CheckedOperationTimeoutException')
  end,
  
  RunCommand.new('zmmemcachedctl', 'zimbra', 'start'),


 ]

#
# Tear Down
#
#
current.teardown = [     
  proxy(mimap1.method('logout')),
  proxy(mimap1.method('disconnect')),
  proxy(mimap2.method('logout')),
  proxy(mimap2.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 


