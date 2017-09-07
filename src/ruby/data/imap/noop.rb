#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#
# IMAP NOOP test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail" 
require "action/waitqueue"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP NOOP test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

Action::WaitQueue.new.run  #Make sure queue is empty before the execution
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: REPLACEME 

Search body message hmm
  Orange 
    Apple
      Pear.
Garbage.
me. "Quoted"
EOF

 
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
  Action::SendMail.new(testAccount.name, message.gsub(/REPLACEME/, testAccount.name)), 
  Action::WaitQueue.new,
   
  NoopVerify.new(mimap), 
  Action::SendMail.new(testAccount.name,message.gsub(/REPLACEME/, testAccount.name)), 
  
  Action::WaitQueue.new,
  proxy(mimap.method('login'),testAccount.name,testAccount.password), 
  proxy(mimap.method('select'),"INBOX"),
  proxy(mimap.method('login'),testAccount.name,testAccount.password),   
  NoopVerify.new(mimap, {'EXISTS' => [2]}), 
  Action::SendMail.new(testAccount.name,message.gsub(/REPLACEME/, testAccount.name)), 
   
  Action::WaitQueue.new,
  NoopVerify.new(mimap, {'EXISTS' => [2, 3]}), 
  proxy(mimap.method('create'),"INBOX/one"),
  proxy(mimap.method('select'),"INBOX/one"),  
  Action::SendMail.new(testAccount.name,message.gsub(/REPLACEME/, testAccount.name)),  
 
  Action::WaitQueue.new,  
  NoopVerify.new(mimap, {'EXISTS' => [0]}), 
  
  proxy(mimap.method('select'),"INBOX"), 
  proxy(mimap.method('store'), (1..-1), "FLAGS", [:Deleted]),
  proxy(mimap.method('close')),
  proxy(mimap.method('select'),"INBOX"), 
  Action::SendMail.new(testAccount.name,message.gsub(/REPLACEME/, testAccount.name)), 
  
  Action::WaitQueue.new,  
  NoopVerify.new(mimap, {'EXISTS' => [1]}), 
  proxy(mimap.method('delete'),"INBOX/one"), 
  NoopVerify.new(mimap, {'EXISTS' => [1]}), 
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
