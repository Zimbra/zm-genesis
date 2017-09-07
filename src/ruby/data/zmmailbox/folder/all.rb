#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 Vmware Zimbra
#
# zmmailbox folder grant all

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
current.description = "Testcase for bug #49412"


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
# Testcase for bug #42855
current.action = [
                  CreateAccount.new(testAccount.name,testAccount.password),
                  v(ZMailAdmin.new('-m', testAccount.name, 'mfg', '/Briefcase', 'all', 'r')) do |mcaller, data|  
                    mcaller.pass = data[0] == 0
                  end,
                  
                  v(ZMailAdmin.new('-m', testAccount.name, 'gfg', '/Briefcase')) do |mcaller, data|  
                    mcaller.pass = data[0] == 0 && data[1].include?('Permissions') &&
                      data[1].include?(' all')
                  end,
                  v(ZMailAdmin.new('-m', testAccount.name, 'mfg', '/Briefcase', 'all', 'none')) do |mcaller, data|  
                    mcaller.pass = data[0] == 0
                  end,
                  
                  v(ZMailAdmin.new('-m', testAccount.name, 'gfg', '/Briefcase')) do |mcaller, data|  
                    mcaller.pass = data[0] == 0 && data[1].include?('Permissions') &&
                      !data[1].include?(' all')
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
