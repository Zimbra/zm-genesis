#!/usr/bin/ruby -w
#
# = action/delete.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP delete test cases
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
current.description = "IMAP Delete test"

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
  #Basic operation 
  proxy(mimap.method('delete'),"INBOX/delete/"), 
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('create'),"INBOX/delete/deleteone") ,  
  DeleteVerify.new(mimap, "INBOX/delete/"),
  SelectVerify.new(mimap, "INBOX/delete/deleteone"),   
  proxy(mimap.method('close')),
  DeleteVerify.new(mimap, "INBOX/delete/deleteone"), 
  proxy(mimap.method('delete'),"abc"), #SEARCH TODO: need something better
  #Error cases
  ["INBOX/", "INBOX", "Calendar/", "Contacts/", "Sent", "Drafts", "Junk", "Trash"].map { |term|
    DeleteVerify.new(mimap, term, &Action::IMAP::DeleteFailed) 
  }   
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