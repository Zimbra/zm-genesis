#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# POP Auth Plain
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"
require "action/zmprov"
require "action/proxy" 
require "action/verify" 
require "net/pop"; require "action/pop"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP Auth Plain"

name = 'pop'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD) 
 


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
   
  #pop action
  [
    [testAccount.name, testAccount.password, testAccount.name, "all filled"],
    [testAccount.name, testAccount.password, '', "authi empty"],
    [testAccount.name, testAccount.password, testAccount.name+"/tb", "tb switch"],
    [adminAccount.name, adminAccount.password, testAccount.name, "admin account credential"],
  ].map do |x|
    v(cb(x[4]) do
      pop = Net::POP3::AuthPlain.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
      pop.start(x[0], x[1], x[2]) 
    end) do |mcaller, data|  
      mcaller.pass = data.started? 
      data.finish  if data.started?# this is actually a pop class
    end
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