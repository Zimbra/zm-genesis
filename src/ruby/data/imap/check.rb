#!/usr/bin/ruby -w
#
# = action/select.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP check test cases
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
current.description = "IMAP Check test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action 
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
  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
  proxy(Kernel.method('sleep'),1),  
  if(Model::TARGETHOST.proxy)
   CheckVerify.new(mimap, &Action::IMAP::ParseError)
  else
   CheckVerify.new(mimap, &Action::IMAP::MustInSelect)
  end,
  Action::SendMail.new(testAccount.name,'Two'), 
  proxy(mimap.method('login'),testAccount.name,testAccount.password),    
  CheckVerify.new(mimap, &Action::IMAP::MustInSelect),
  proxy(mimap.method('select'),"INBOX"),
  proxy(mimap.method('login'),testAccount.name,testAccount.password), 
  CheckVerify.new(mimap),
  Action::SendMail.new(testAccount.name,'Three'), 
  CheckVerify.new(mimap),
  proxy(mimap.method('select'),"ASDFASDF"),
  proxy(mimap.method('select'),"INBOX"),
  proxy(mimap.method('close')),  
  CheckVerify.new(mimap, &Action::IMAP::MustInSelect),  
  proxy(mimap.method('select'),"INBOX"),
  CheckVerify.new(mimap),
  proxy(mimap.method('create'),"INBOX/one"),
  proxy(mimap.method('examine'),"INBOX/one"),  
  Action::SendMail.new(testAccount.name,'Four'), 
  proxy(Kernel.method('sleep'),1), 
  CheckVerify.new(mimap),
  proxy(mimap.method('select'),"INBOX"), 
  Action::SendMail.new(testAccount.name,'Five'), 
  proxy(Kernel.method('sleep'),5), 
  CheckVerify.new(mimap),
  proxy(mimap.method('delete'),"INBOX/one"), 
  CheckVerify.new(mimap)
  
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 