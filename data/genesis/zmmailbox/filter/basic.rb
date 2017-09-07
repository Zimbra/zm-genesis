#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
# zmmailbox filter basic test

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
current.description = "Zmmailbox filter test-cases"

 
include Action

name = 'zmmailbox'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
 
#
# Setup
#
current.setup = [
 
]

#
# Execution
#
current.action = [

# Start bug 58197
   CreateAccount.new(testAccount.name,testAccount.password),
   v(ZMailAdmin.new('-m', testAccount.name, 'afrl from any header', '"from"', 'contains', '\"', 'discard')) do |mcaller, data|  
     mcaller.pass = (data[0] == 0) 
   end, 
   v(ZMailAdmin.new('-m', testAccount.name, 'gfrl')) do |mcaller, data|  
       mcaller.pass = (data[0] == 0) && !data[1].include?("WARN") || !data[1].include?("ERROR")
     end, 
# End bug 58197 
  
]
#
# Tear Down
#
current.teardown = [    
      
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end