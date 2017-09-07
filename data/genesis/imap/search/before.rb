#!/usr/bin/ruby
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
# IMAP SEARCH before test cases
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


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search Before test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD) 
m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org
BCC: testmeREPLACEME@ruby-lang.org

Search before message REPLACEME
EOF
 
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
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/before"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/before",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.at(946702800+i*3600*24)) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/before"), 
  {
    "20-Jan-3000" => (temp = (1..20).to_a), "21-Jan-2000" => temp,
    "20-Jan-2000" => (1..19).to_a, "19-Jan-2000" => (1..18).to_a 
  }.sort.map do |x|
    SearchVerify.new(m, ["BEFORE", x[0]], x[1])
  end,    
  UidsearchVerify.new(m, ["BEFORE","20-Jan-3000"], 20),  
  SearchVerify.new(m, ["NOT", "BEFORE","20-Jan-2000"], [20]),
  SearchVerify.new(m, ["BEFORE","19-Jan-2000","BEFORE","19-Jan-2000"], (1..18).to_a), 
  SearchVerify.new(m, ["BEFORE","19-Jan-1980"], &IMAP::EmptyArray),  
  #p(m.method('delete'),"INBOX/before"),  
]

#
# Tear Down
#
current.teardown = [     
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end