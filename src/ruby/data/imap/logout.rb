#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2015 Zimbra
#
# Imap logout tests

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail" 
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP LOGOUT test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap3 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
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
  
  v(RunCommand.new('echo', 'root', "\"a01 logout\" | openssl s_client -host localhost -port #{Model::IMAP} -starttls imap -quiet")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select{|w| w =~ /^\*\s+BYE.*/}.size == 1
  end,
  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
  LogoutVerify.new(mimap), 
  proxy(mimap2.method('login'),testAccount.name,testAccount.password),  
  LogoutVerify.new(mimap2),
 
  proxy(mimap3.method('login'),testAccount.name,testAccount.password), 
  proxy(mimap3.method('select'),'INBOX'),  
  LogoutVerify.new(mimap3),
 
]

#
# Tear Down
#
current.teardown = [   
  proxy(mimap.method('disconnect')),    
  proxy(mimap2.method('disconnect')),  
  proxy(mimap3.method('disconnect')),   
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
 