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
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/decorator"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue"
require "action/zmprov"


require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Create Bug Case"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action
mimap = d

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
                  Action::SendMail.new(testAccount.name,'DummyMessageOne'), 
                  Action::WaitQueue.new,
                  #Basic operation 
                  cb("Imap connection initialization") do
                    mimap.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
                  end,                
                  proxy(mimap, 'login', testAccount.name,testAccount.password), 
                  proxy(mimap, 'create', "INBOX/three/four"), 
                  SelectVerify.new(mimap, "INBOX/three/four"),
                  SelectVerify.new(mimap, "INBOX/three"),  
                  StatusVerify.new(mimap, "INBOX/three/four", ["UIDVALIDITY"]),
                  StatusVerify.new(mimap, "INBOX/three", ["UIDVALIDITY"]),   
                  proxy(mimap, 'delete',"INBOX/three/four"), 
                  proxy(mimap, 'delete',"INBOX/three"), 
                  
                  SelectVerify.new(mimap, "INBOX/three/four") { |caller, data|   
                    caller.pass = (data.class == Net::IMAP::NoResponseError) &&
                    (data.message == 'SELECT failed')  
                  },
                  
                  SelectVerify.new(mimap, "INBOX/three") { |caller, data|
                    caller.pass = (data.class == Net::IMAP::NoResponseError) &&
                    (data.message == 'SELECT failed')  
                  },   
                  
                  proxy(mimap, 'create',"INBOX/three/four"), 
                  SelectVerify.new(mimap, "INBOX/three/four"),
                  SelectVerify.new(mimap, "INBOX/three"), 
                  StatusVerify.new(mimap, "INBOX/three/four", ["UIDVALIDITY"]),
                  StatusVerify.new(mimap, "INBOX/three", ["UIDVALIDITY"]),     
                 ]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap, 'logout'),
  proxy(mimap, 'disconnect'),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
