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
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "set"
require 'yaml'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Append Thunderbird test"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)


 
#
# Setup
#
current.setup = [
  
]
message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Subject: hello
From: genesis@test.org
Date: Wed, 20 Sep 2005 15:15:14 -0700 (PDT)
To: REPLACEME

hello world
EOF
message2 = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Subject: hello
From: genesis@test.org 
To: REPLACEME

hello world
EOF
#
# Execution
#
current.action = [   
  CreateAccount.new(testAccount.name,testAccount.password), 
   
    
  # Issue append before login
 
  p(mimap.method('login'),testAccount.name+"/tb",testAccount.password),
  
  # Simple append command
  p(mimap.method('create'),"INBOX/append"),
  v(
    p(mimap.method('append'),"INBOX/append", message, [:Answered, :Deleted, :Draft, :Flagged, :Seen])
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
      (data.name == "OK")       
  },
    v(
    p(mimap.method('append'),"INBOX/append", message2, [:Answered, :Deleted, :Draft, :Flagged, :Seen])
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
      (data.name == "OK")       
  },
  
  p(mimap.method('select'),"INBOX/append"),
  v(
    p(mimap.method('fetch'), 1, "ALL")
  ){ |caller, data|     
    caller.pass = (data[0].class == Net::IMAP::FetchData) &&     
     
      (data[0].attr['INTERNALDATE']  == '20-Sep-2005 15:15:14 -0700') 
  },
  # Verify that no header use current time, weak verification method
  v(
    p(mimap.method('fetch'), 2, "ALL")
  ){ |caller, data|     
    caller.pass = (data[0].class == Net::IMAP::FetchData) &&  
     
      (data[0].attr['INTERNALDATE']  != '20-Sep-2005 15:15:14 -0700') 
  },
 
  p(mimap.method('delete'), "INBOX/append"),
 
  p(mimap.method('logout')),
  
]

#
# Tear Down
#
current.teardown = [      
  p(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 