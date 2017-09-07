#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# zmprov mailbox basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/decorator"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Mailbox Basic test"


include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
mimap = d

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

  #MaiboxInfo
  v(ZMProv.new('gmi',adminAccount)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('mailboxId')
  end,

  #Get Quota Usage
  v(ZMProv.new('gqu',Model::TARGETHOST.to_s)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?(adminAccount.name)
  end,

  #reIndexMailbox
   v(ZMProv.new('rim', adminAccount.name, 'start' )) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('status: started')
  end,

  #selectMailbox
   v(ZMProv.new('sm', adminAccount.name,'gaf' )) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('Inbox')
  end,

  #RecalculateMailboxCounts
  v(ZMProv.new('rmc', adminAccount.name )) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('quotaUsed')
  end,

 #RecalculateMailboxCounts
  v(ZMProv.new('RecalculateMailboxCounts', adminAccount.name )) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('quotaUsed')
  end,
  
  # Start Bug 63257, Run VerifyIndex on account without mailbox and on empty account.
  v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('verifyIndex',testAccount.name)) do |mcaller, data|
                
   mcaller.pass = data[0] != 0 && data[1].include?('system failure: mailbox not found for account')
  end,
  cb("setup imap") do
    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
  end,
  #Login to create mailbox
  LoginVerify.new(mimap, testAccount.name, testAccount.password),
  cb("delay for timing issue") do
     sleep(10)
  end,
  v(ZMProv.new('verifyIndex',testAccount.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('index does not exist')
  end,
 # End Bug 63257 

]
#
# Tear Down
#
current.teardown = [

]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance, true).run
end
