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
# IMAP select test cases
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
current.description = "IMAP Select test"

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
  proxy(mimap.method('select'),"INBOX"), 
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('create'),"INBOX/one"),
  proxy(mimap.method('create'),"INBOX/two"),
  proxy(mimap.method('create'),"INBOX/three/three"), 
  proxy(mimap.method('create'),"five"),
  SelectVerify.new(mimap, 'five'), 
  proxy(mimap.method('delete'),"five"), 
  SelectVerify.new(mimap, 'five', &IMAP::SelectFailed),
  ["INBOX", "Trash", "INBOX/one", "INBOX/three", "INBOX/three/three"].map do |x|
    SelectVerify.new(mimap, x)
  end, 
  
  ['Notebook', 'Trash/five', 'abc', '', 'Calendar', '*', 'Calendar/hi'].map do |x|
    SelectVerify.new(mimap, x, &IMAP::SelectFailed)
  end, 
  
  v(proxy(mimap.method('status'), 'INBOX', ["MESSAGES", "RECENT", "UIDNEXT","UNSEEN", 
    "UIDVALIDITY"])) do |mcaller, data| 
    mcaller.pass = (Hash === data) && 
      %w[MESSAGES RECENT UNSEEN UIDVALIDITY].inject(true) do |meta, object| 
        meta && data.has_key?(object)
      end
  end,
  
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
 