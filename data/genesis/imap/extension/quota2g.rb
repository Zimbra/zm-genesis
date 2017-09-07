#!/usr/bin/ruby -w
#
# = data/imap/extension/quota.rb
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

require "action/decorator"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Quota over 2gb test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)


mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
include Action

 
#
# Setup
#
current.setup = [
  
]
 
#
#
# Execution
#
current.action = [      
  CreateAccount.new(testAccount.name,testAccount.password), 
  ZMProv.new("ma #{testAccount.name} zimbraMailQuota 4194304000"),
  p(mimap.method('login'),testAccount.name,testAccount.password),    
  v(cb("Quota INBOX Root") do 
    mimap.method('send_command').call('GETQUOTAROOT INBOX')
    mimap.responses 
  end) do |mcaller, data| 
    mcaller.pass = (data.class == Hash) && data.has_key?('QUOTAROOT') &&
      (data['QUOTAROOT'].size > 0) &&
      (data['QUOTAROOT'].first.quotaroots.first == "") &&
      (data['QUOTA'].size > 0) &&
      (data['QUOTA'].first.quota == "4096000")
  end, 
   
  p(mimap.method('delete'),"INBOX/quota"), 
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