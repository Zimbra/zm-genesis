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
# IMAP authentication via ssl test cases
# 


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Auth Test over SSL"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

 
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
  v(
    proxy(mimap.method('login'),testAccount.name,testAccount.password)     
  ){ |mcaller, data|
    mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
       (data.name == 'OK') &&
       (data.raw_data.include?('completed'))
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