#!/usr/bin/ruby -w
#
# = action/close.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP close t test cases
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
current.description = "IMAP Close test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
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
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [   
  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
  #Basic operation 
  if(Model::TARGETHOST.proxy)
    CloseVerify.new(mimap,  &Action::IMAP::ParseError)
  else
    CloseVerify.new(mimap, &Action::IMAP::MustInSelect)
  end, 
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('create'),"INBOX/delete/deleteone") , 
  CloseVerify.new(mimap, &Action::IMAP::MustInSelect), 
  proxy(mimap.method('select'),"INBOX/delete/deleteone"),
  proxy(mimap.method('append'),"INBOX/delete/deleteone", message, [:Seen], Time.at(945702800)),
  proxy(mimap.method('append'),"INBOX/delete/deleteone", message, [:Deleted], Time.at(945702800)),
  proxy(mimap.method('status'), "INBOX/delete/deleteone", flags),
  CloseVerify.new(mimap),
  proxy(mimap.method('status'), "INBOX/delete/deleteone", flags),
  proxy(mimap.method('delete'), "INBOX/delete/deleteone"),
  
  # On exam it is immutable
  proxy(mimap.method('create'),"INBOX/delete/deletetwo") , 
  proxy(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Seen], Time.at(945702800)),
  proxy(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Deleted], Time.at(945702800)),
  proxy(mimap.method('examine'),"INBOX/delete/deletetwo"),
  proxy(mimap.method('status'), "INBOX/delete/deletetwo", flags),
  CloseVerify.new(mimap),
  proxy(mimap.method('status'), "INBOX/delete/deletetwo", flags),
  proxy(mimap.method('delete'), "INBOX/delete/deletetwo"),
  
  # Double close should generate error
  proxy(mimap.method('select'), "INBOX"),
  CloseVerify.new(mimap),
  CloseVerify.new(mimap, &Action::IMAP::MustInSelect),
  proxy(mimap.method('logout')),  
  

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