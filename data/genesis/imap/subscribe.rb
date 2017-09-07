#!/usr/bin/ruby -w
#
# = action/subscribe.rb
#
# Copyright (c) 2005 Zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Subscribe test cases
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP SUBSCRIBE test"

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
  
  v(proxy(mimap.method('send_command'),'subscribe'), &IMAP::ParseError),  
  [' ', ' something', ' something something'].map do |x|
      if(Model::TARGETHOST.proxy)  
        v(proxy(mimap.method('send_command'),'subscribe',x),  &Action::IMAP::ParseError)
      else  
        v(proxy(mimap.method('send_command'),'subscribe',x), &IMAP::MustInAuthSelect)
      end 
  end,  
 
  proxy(mimap.method('login'),testAccount.name,testAccount.password), 
  proxy(mimap.method('create'),"INBOX/one/two"), 
  ["", "Calendar"].map do |x|
    SubscribeVerify.new(mimap, x, &IMAP::SubscribeFailed)  
  end,
  
  proxy(mimap.method('select'),"INBOX"), 
  ['INBOX', 'Sent', 'Drafts', 'Trash', 'Junk', "INBOX/one/two"].map do |x|
    SubscribeVerify.new(mimap, x)
  end,
           
  # TODO a way to make search folder    
  #v(proxy(mimap.method('lsub'),"","INBOX/one/%")){}, 
  LsubVerify.new(mimap, "", "INBOX/one/%", [['INBOX/one/two', []]]),
  proxy(mimap.method('delete'),"INBOX/one/two"),
  proxy(mimap.method('delete'),"INBOX/one"),
  proxy(mimap.method('lsub'),"","*"),      
  proxy(mimap.method('lsub'),"","INBOX/one/%"), 
  proxy(mimap.method('logout'))  
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