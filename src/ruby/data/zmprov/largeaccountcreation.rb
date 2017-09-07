#!/usr/bin/ruby -w
#
# = zmprov/largeaccountcreation.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# Zmprov creating large set of accounts test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov" 
require "action/runcommand"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZMProv GAA large account set test" 
 
adminAccount = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD)
numberOfUser = 20000
 
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
   
  CreateAccounts.new('zmprovgaa', Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD), 
  v(ZMProv.new('gaa')) do |mcaller, data|
    mcaller.pass = data[1].split.select do |w|
      w =~ /^zmprovgaa/
    end.size == numberOfUser
  end,
  DeleteAccounts.new('zmprovgaa', Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD)  
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