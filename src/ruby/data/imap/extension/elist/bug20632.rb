#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
#
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/verify"



#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP List extension test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 

#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [  
  Action::CreateAccount.new(testAccount.name,testAccount.password),
  p(mimap.method('login'),testAccount.name,testAccount.password), 
  p(mimap.method('create'), "imaptest/"),
  p(mimap.method('create'), "imaptest/test2/"),
  p(mimap.method('create'), "imaptest/test2/test1"),
 
  v(cb("Bug 20632") do
      mimap.subscribe("imaptest/test2/test1")
      response = mimap.elist('', %w(imaptest/test2 imaptest/test2/test1), %w[RECURSIVEMATCH SUBSCRIBED])
    end) do |mcaller,data|
       mcaller.pass = (data.size == 1)
  end,
                  
  p(mimap.method('logout')),
  p(mimap.method('disconnect')),
]

#
# Tear Down
#
current.teardown = [     
    
  Action::DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
