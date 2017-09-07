#!/usr/bin/ruby -w
#
# = data/imap/extension/unselect.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Extension unselect test cases
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
current.description = "IMAP Unselect test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
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
    UnselectVerify.new(mimap, &IMAP::ParseError)
  else
    UnselectVerify.new(mimap, &IMAP::MustInSelect)
  end,
  p(mimap.method('login'),testAccount.name,testAccount.password),
  p(mimap.method('create'),"INBOX/delete/deleteone") ,  
  UnselectVerify.new(mimap, &IMAP::MustInSelect),
  
  p(mimap.method('select'),"INBOX/delete/deleteone"),
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Seen], Time.at(945702800)),
  p(mimap.method('append'),"INBOX/delete/deleteone", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('status'), "INBOX/delete/deleteone", flags),  
  UnselectVerify.new(mimap),
  p(mimap.method('status'), "INBOX/delete/deleteone", flags),
  p(mimap.method('delete'), "INBOX/delete/deleteone"),
  
  # On exam it is immutable
  p(mimap.method('create'),"INBOX/delete/deletetwo") , 
  p(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Seen], Time.at(945702800)),
  p(mimap.method('append'),"INBOX/delete/deletetwo", message, [:Deleted], Time.at(945702800)),
  p(mimap.method('examine'),"INBOX/delete/deletetwo"),
  p(mimap.method('status'), "INBOX/delete/deletetwo", flags), 
  UnselectVerify.new(mimap),
  p(mimap.method('status'), "INBOX/delete/deletetwo", flags),
  p(mimap.method('delete'), "INBOX/delete/deletetwo"),
  
  # Double close should generate error
  p(mimap.method('select'), "INBOX"),
  UnselectVerify.new(mimap),
  UnselectVerify.new(mimap, &IMAP::MustInSelect), 
  p(mimap.method('logout')),  
  

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