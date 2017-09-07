#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# zmmailbox admin basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmmailbox Admin Basic test"

 
include Action

name = 'zmmailbox'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
 
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
  v(ZMailAdmin.new('aa', testAccount.name, testAccount.password)) do |mcaller, data|     
    mcaller.pass = data[1].include?('PERM_DENIED')
  end,
  v(ZMailAdmin.new('aa', adminAccount.name, adminAccount.password)) do |mcaller, data|     
    mcaller.pass = data[0] == 0
  end,
  v(ZMailAdmin.new('aa', adminAccount.name, adminAccount.password+'bad')) do |mcaller, data|     
    mcaller.pass = data[1].include?('AUTH_FAILED')
  end,
  v(ZMailAdmin.new('aa', testAccount.name+'i', testAccount.password)) do |mcaller, data|     
    mcaller.pass = data[1].include?('AUTH_FAILED')
  end,
  v(ZMailAdmin.new('sm', testAccount.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?(testAccount.name)
  end,
  v(ZMMail.new('-m', testAccount.name, '-p', testAccount.password, 'sm', testAccount.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 2) && data[1].include?('CLIENT_ERROR')
  end,
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