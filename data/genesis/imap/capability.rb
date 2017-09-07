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
# IMAP capability test cases
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
current.description = "IMAP Capability test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD) 
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

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
  CapabilityVerify.new(mimap),
  v(
    proxy(mimap.method('send_command'),"capability", "foo")
  ) { |mcaller, data|
    mcaller.pass = (data.class == Net::IMAP::BadResponseError) 
  },
  
  proxy(mimap.method('login'),testAccount.name,testAccount.password),  
  CapabilityVerifyNoAuth.new(mimap),
  proxy(mimap.method('select'),"INBOX"),  
  CapabilityVerifyNoAuth.new(mimap),  
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
]

#
# Tear Down
#
current.teardown = [      
 
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 