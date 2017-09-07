#!/usr/bin/ruby -w
#
# = action/examine.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP examine test cases
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
current.description = "IMAP Examine test"

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
  proxy(Kernel.method('sleep'),5),  
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('create'),"INBOX/one"),
  proxy(mimap.method('create'),"INBOX/two"),
  proxy(mimap.method('create'),"INBOX/three/three"), 
  proxy(mimap.method('create'),"five"), 
  
  ExamineVerify.new(mimap, "five"),  
  proxy(mimap.method('delete'),"five"),
  ExamineVerify.new(mimap, "five", &IMAP::ExamineFailed), 
  proxy(mimap.method('examine'),"Trash/five"),
  ExamineVerify.new(mimap, "Trash/five", &IMAP::ExamineFailed),
  
  proxy(mimap.method('select'),"INBOX"), 
  proxy(mimap.method('store'), 1, "+FLAGS", [:Seen]),   
  ExamineVerify.new(mimap, "INBOX", [:Seen]),
  
  proxy(mimap.method('fetch'), 1, "FLAGS"),
  proxy(mimap.method('store'), 1, "+FLAGS", [:Deleted]),
  proxy(mimap.method('fetch'), 1, "FLAGS"),
  
  ["Trash", 'INBOX/one','INBOX/three','INBOX/three/three'].map { |x|
    ExamineVerify.new(mimap, x)
  },
 
  ['Notebook', 'Calendar', "", "*", 'Calendar/hi'].map { |x|
    ExamineVerify.new(mimap, x, &IMAP::ExamineFailed)     
  },
  
  proxy(mimap.method('status'), 'INBOX', ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", "UIDVALIDITY"]),
  proxy(mimap.method('status'), 'abc', ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", "UIDVALIDITY"]),
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