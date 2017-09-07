#!/usr/bin/ruby -w
#
# = action/examineneagtive.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP select test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/decorator"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/sendmail"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Examine Negative test"

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
  if(Model::TARGETHOST.proxy)  
    ExamineVerify.new(mimap, 'INBOX', &Action::IMAP::ParseError)
  else  
    ExamineVerify.new(mimap, 'INBOX', &IMAP::MustInAuthSelect)
  end,
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('create'),"INBOX/one"),
  proxy(mimap.method('create'),"INBOX/two"),
  proxy(mimap.method('create'),"INBOX/three/three"),
  ['nowhere', '\Answered', '=me', '///', '\\\\', ''].map do |x|
    ExamineVerify.new(mimap, x, &IMAP::ExamineFailed)
  end, 
  proxy(mimap.method('status'), 'INBOX', ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", "UIDVALIDITY"]),
  proxy(mimap.method('delete'),"INBOX/three/three"),
  proxy(mimap.method('delete'),"INBOX/three"),
  proxy(mimap.method('delete'),"INBOX/two"),
  proxy(mimap.method('delete'),"INBOX/one")
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