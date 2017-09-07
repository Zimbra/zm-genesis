#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov"
require "action/proxy" 
require "action/zmamavisd"

require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Bye test"

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
  proxy(mimap.method('login'),testAccount.name,testAccount.password),  
  v(cb("BYE after shutdown", 120) do 
    Action::ZMMailboxdctl.new('restart').run
    mimap.responses
  end) do |mcaller, data|  
    mcaller.pass = data.key?('BYE') 
  end,
  cb("Sleep 5 seconds") { Kernel.sleep(5)  },
  if Model::TARGETHOST.proxy
    [
    v(cb("BYE after Nginx error") do
      mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
      begin
        mResult = mTemp.login(testAccount.name, "fake")
      rescue
        mResult = mTemp
      end
      mResult
    end) do |mcaller, data|
      mcaller.pass = data.responses.key?("BYE")
    end
    ]
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
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 
