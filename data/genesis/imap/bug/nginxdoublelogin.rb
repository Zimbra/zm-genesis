#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
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
current.description = "NGINX double login test bug#30545"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap) 
mimap2 = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
mimap3 = nil
mimap4 = nil

include Action
Net::IMAP.add_authenticator('PLAIN', PlainAuthenticator)

#Net::IMAP.debug = true
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
  if(Model::TARGETHOST.proxy == true)
    [ 
    LoginVerify.new(mimap, testAccount.name[/([^@]*)/], testAccount.password),
    LoginVerify.new(mimap2, testAccount.name[/([^@]*)/], testAccount.password),]  
  end
]

#
# Tear Down
#
current.teardown = [
  proxy(mimap.method('logout')),  
  proxy(mimap2.method('logout')),                     
  proxy(mimap.method('disconnect')),  
  proxy(mimap2.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end