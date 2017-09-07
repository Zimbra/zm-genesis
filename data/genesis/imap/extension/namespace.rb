#!/usr/bin/ruby -w
#
# = data/imap/extension/namespace.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Extension namespace test cases
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
current.description = "IMAP Namespace test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
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
  if(Model::TARGETHOST.proxy)   
     NamespaceVerify.new(mimap,'before login', &IMAP::ParseError)
  else   
     NamespaceVerify.new(mimap,'before login', &IMAP::MustInAuthSelect)
  end,
  p(mimap.method('login'),testAccount.name,testAccount.password), 
  NamespaceVerify.new(mimap,'after login'),
  p(mimap.method('select'),"INBOX"),  
  NamespaceVerify.new(mimap,'after select'),
  NamespaceVerify.new(mimap,'double namespace'), 
  p(mimap.method('logout')) 
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