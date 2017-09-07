#!/usr/bin/ruby -w
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

require "net/imap"; require "action/imap" #Patch Net::IMAP library

require "model" 
require "action/block" 

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify" 
require "set"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Multiple Append test"

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
To: REPLACEME

hello world
EOF
#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  cb("Send an email") {
    SendMail.new(testAccount.name,message).run
  }, 
  p(mimap.method('login'),testAccount.name,testAccount.password),
  
  # Simple append command
  p(mimap.method('create'),"INBOX/append"),
  v(
    p(mimap.method('mappend'),"INBOX/append", [message.gsub(/hello/,"helloOne"), message.gsub(/hello/,"helloTwo")], [:Answered, :Deleted, :Draft, :Flagged, :Seen], Time.at(945702800))
  ) { |caller, data|
    results = data.data.code.data.split 
    caller.pass = results[0].to_i != 0
    mimap.select("INBOX/append") 
    mimap.method('send_command').call("UID FETCH #{results[1]} ALL")
        
    caller.pass = mimap.responses['FETCH'].first.attr['ENVELOPE'].subject == 'helloOne' &&
      mimap.responses['FETCH'].last.attr['ENVELOPE'].subject == 'helloTwo' rescue false
  },
  
  p(mimap.method('select'),"INBOX/append"),
  v(
    p(mimap.method('fetch'), 1, "ALL")
  ){ |caller, data| 
 
    caller.pass = (data[0].class == Net::IMAP::FetchData) && 
      (data[0].attr['FLAGS'].to_set == (Set.new [:Deleted, :Draft, :Flagged, :Answered, :Seen])) &&
      (data[0].attr['ENVELOPE'].from[0].mailbox == 'genesis') &&
      (data[0].attr['ENVELOPE'].from[0].host == 'test.org') &&
      (data[0].attr['ENVELOPE'].sender[0].mailbox == 'genesis') &&
      (data[0].attr['ENVELOPE'].sender[0].host == 'test.org') 
  },
 
  p(mimap.method('delete'), "INBOX/append"),
   
  p(mimap.method('logout')),
  p(mimap.method('disconnect')),  
  
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