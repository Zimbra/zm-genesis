#!/usr/bin/ruby -w
#
# = action/expunge.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP expundge test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/sendmail"
require "action/waitqueue"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Expunge test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

hello world
EOF

flags = ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", "UIDVALIDITY"]
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
  #Basic operation 
  p(mimap.method('expunge')), 
  p(mimap.method('login'),testAccount.name,testAccount.password),
  p(mimap.method('create'),"INBOX/delete/deleteone") ,  
  ExpungeVerify.new(mimap, 'INBOX/delete/deleteone', &IMAP::MustInSelect), 
  
  p(mimap.method('select'),"INBOX/delete/deleteone"),
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Seen], Time.at(945702800)),
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('status'), "INBOX/delete/deleteone", flags),
  ExpungeVerify.new(mimap, 'INBOX/delete/deleteone', { 'RECENT' => [0, 1, 2, 1]}), 
  
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('send_command'),"uid expunge 1:*"),
  p(mimap.method('status'), "INBOX/delete/deleteone", flags),
  p(mimap.method('delete'), "INBOX/delete/deleteone"),
  
  # On exam it is immutable
  p(mimap.method('create'),"INBOX/delete/deletetwo") , 
  p(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Seen], Time.at(945702800)),
  p(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('examine'),"INBOX/delete/deletetwo"),
  p(mimap.method('status'), "INBOX/delete/deletetwo", flags), 
  ExpungeVerify.new(mimap, 'INBOX/delete/deleteone', &IMAP::ReadOnly), 
  
  p(mimap.method('status'), "INBOX/delete/deletetwo", flags),
  p(mimap.method('delete'), "INBOX/delete/deletetwo"),
  
  # Double expunge should not generate error
  p(mimap.method('select'), "INBOX"), 
  ExpungeVerify.new(mimap, 'INBOX'), 
  ExpungeVerify.new(mimap, 'INBOX'),    
  p(mimap.method('logout')),  
  

 ]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('disconnect')),   
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
