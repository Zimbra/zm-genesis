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


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
  require 'engine/simple'
  require 'data/multinode/setup'
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 

require "model"
require "action/block"

require "action/mailboxmove" 
require "action/verify"
require "action/zmprov"
require "action/zmmailbox"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Verify zmmailboxmove for account with special characters in name."
name = 'zmmove&'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
origHost = Model::TARGETHOST
destHost = Model::TARGETHOST.findService(:service)[-1]
runThisTest = (origHost != destHost)
testAccount = origHost.cUser(name, Model::DEFAULTPASSWORD)


include Action

#
# Setup
#
current.setup = [
                 
                ]

#
# Execution
#
if(runThisTest)
  current.action = [    
                    # Bug #18025
                    # Create account
                    CreateAccount.new('"%s"'%testAccount.name, testAccount.password),  
                    
                    # Move account to slave host
                    v(cb("Move account to slave host") do    
                        MailMove.new('-a', '"%s"'%testAccount.name, '-s',  origHost.to_s, '-t',  destHost.to_s).run
                      end) do |mcaller, data|
                      mcaller.pass = data[0] == 0 && !data[1].include?('Error') || !data[1].include?('system failure')
                    end,

                    #Get Account's mailhost after move
                    v(ZMProv.new('ga', '"%s"'%testAccount.name, 'zimbraMailHost')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0) && (data[1].include?(destHost.to_s))
                    end,                  
                    
                   ]
else
  current.action = []
end
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
