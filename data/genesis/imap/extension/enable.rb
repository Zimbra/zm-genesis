#!/usr/bin/ruby -w
#
# = data/imap/fetch/basic.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP BUG 18247 HIGHMODESEQUENCE
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 


 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/zmmailbox"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP ENABLE"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
#m = Net::IMAP.new(Model::TARGETHOST, 7143)

include Action

 
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
  v(cb("enable before login") do
    m.enable("FOO")
  end) do |mcaller, data|
    if Model::TARGETHOST.proxy
       mcaller.pass = data.class ==  Net::IMAP::BadResponseError
    else
       mcaller.pass = data.class ==  Net::IMAP::NoResponseError
    end 
  end, 
  p(m.method('login'),testAccount.name,testAccount.password),
  cb("enable condstore") do 
    m.enable("CONDSTORE")
  end,
  p(m.method('create'),"INBOX/FETCHBASIC"), 
  v(cb("check select") do
    m.select("INBOX/FETCHBASIC")
    m.responses
  end) do |mcaller, data|
    mcaller.pass = data.key?('HIGHESTMODSEQ')
  end, 
  p(m.method('delete'),"INBOX/FETCHBASIC"),  
]

#
# Tear Down
#
current.teardown = [     
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end