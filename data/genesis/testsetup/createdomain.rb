#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov"
require "action/verify"

include Action

current = Model::TestCase.instance()
current.description = "Create custom domain and admin account" 

#
# Global variable declaration
#

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [    
   v(ZMProv.new('cd', Model::DOMAIN.to_s)) do |mcaller, data|
      mcaller.pass = data[0] == 0
   end,
 
   v(ZMProv.new('ca', 'admin@'+Model.DOMAIN.to_s, Model::DEFAULTPASSWORD, 'zimbraIsAdminAccount', 'TRUE')) do |mcaller, data|
      mcaller.pass = data[0] == 0    
   end,
]

#
# Tear Down
#
current.teardown = [     
  
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, false).run  
end