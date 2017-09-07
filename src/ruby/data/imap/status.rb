#!/usr/bin/ruby -w
#
# = action/status.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP status test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "action/waitqueue"
require "action/decorator"



#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Status test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action
mimap = d
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

flags = ["MESSAGES", "RECENT","UNSEEN", "UIDVALIDITY"]
#
# Execution
#
current.action = [  
                  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
                  Action::WaitQueue.new,
                  cb("Imap connection initialization") do
                    mimap.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
                  end,
                  proxy(mimap,'status',"INBOX", flags), 
                  proxy(mimap,'login',testAccount.name,testAccount.password),
                  proxy(mimap,'create',"INBOX/one"),
                  proxy(mimap,'create',"INBOX/two"),
                  proxy(mimap,'create',"INBOX/three/three"), 
                  proxy(mimap,'create',"five"),  
                  StatusVerify.new(mimap, 'five', flags),
                  proxy(mimap,'delete',"five"),  
                  StatusVerify.new(mimap, 'five', flags, &IMAP::StatusFailed), 
                  StatusVerify.new(mimap, 'Trash/five', flags, &IMAP::StatusFailed),
                  ['INBOX', 'INBOX/one', 'INBOX/three', 'INBOX/three/three'].map do |x|
                    StatusVerify.new(mimap, x, flags)
                  end,
                  
                  ['', 'Calendar', '*', 'Calendar/hi'].map do |x|
                    StatusVerify.new(mimap, x, flags, &IMAP::StatusFailed)
                  end,  
                  
                  proxy(mimap,'delete',"INBOX/three/three"),
                  proxy(mimap,'delete',"INBOX/three"),
                  proxy(mimap,'delete',"INBOX/two"),
                  proxy(mimap,'delete',"INBOX/one"),
                  
                  #Status must not lost select focus
                  proxy(mimap,'select',"INBOX"),
                  Action::SendMail.new(testAccount.name,'selecttest'), 
                  Action::WaitQueue.new,
                  proxy(mimap,'status', 'abc', flags), 
                  StatusVerify.new(mimap, 'nohere', flags, &IMAP::StatusFailed),
                  proxy(mimap,'noop'),
                  proxy(mimap,'logout'),
                  
                 ]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap,'disconnect'),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
