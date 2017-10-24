#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 Zimbra
#
# IMAP Extension ID test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP ID test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD) 
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 

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
  CreateAccount.new(testAccount.name,testAccount.password),
  # bug 67853 - keys should not be case sensitive; x-via and x-originating-ip
  if (Model::TARGETHOST.proxy != true)
    [
      IDVerify.new(mimap, 'before login', '("x-vIa" "testclient" "nAmE" "FF" "vErSiOn" "10.13")'),
      p(mimap.method('login'),testAccount.name,testAccount.password),
      ## TODO - use log checker
      v(RunCommandOnMailbox.new('tail', 'root', '-n15', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))) do | mcaller, data |
        mcaller.pass = data[1].include?('via=testclient;ua=FF/10.13')
      end
    ]
  else
    # bug 64978 - Nginx should pass name and version from ID to ZCS
    # and disregard anything else like x-via
    [
      IDVerify.new(mimap, 'before login', '("x-vIa" "testclient" "nAmE" "FF" "vErSiOn" "10.13")'),
      p(mimap.method('login'),testAccount.name,testAccount.password),
      ## TODO - use log checker
      v(RunCommandOnMailbox.new('tail', 'root', '-n15', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))) do | mcaller, data |
        mcaller.pass = data[1].match(/via=FF\/10\.13,.+nginx.+ua=Zimbra/)
      end
    ]
  end,
  IDVerify.new(mimap, 'after login'),
  p(mimap.method('select'),"INBOX"),  
  IDVerify.new(mimap, 'after select'),
  IDVerify.new(mimap, 'double IDLE'), 
  IDVerify.new(mimap, 'xoip', '("X-ORIGINATING-IP" "192.168.204.128")'), 
  p(mimap.method('logout')) 
]

#
# Tear Down
#
current.teardown = [    
  p(mimap.method('disconnect')),    
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
