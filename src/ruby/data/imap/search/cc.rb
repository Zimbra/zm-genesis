#!/usr/bin/ruby -w
#
# = data/imap/cc.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH cc test cases
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search CC test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@test.org
Cc: testmeREPLACEME@ruby-lang.org, REPLACEME@hi.com

Search message REPLACEME
EOF
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/cc"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/cc",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 

  p(m.method('examine'),"INBOX/cc"), 
  [["CC", "none"]].map do |x|
    SearchVerify.new(m, x, &IMAP::EmptyArray)
  end,  
  
  { ["CC" ,'testme1@ruby-lang.org'] => (y = [1]),
    ["CC" ,'testme1'] => y,
    ["NOT", "CC",'testme1'] => (2..9).to_a << 20,
    ["OR", "CC",'testme1', "CC", 'testme2'] => y    
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,   
  
  v(p(m.method('send_command'),'SEARCH OR (CC testme1 CC testme2) CC testme3')) do |mcaller, data|
    mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
      (data.data.class == Net::IMAP::ResponseText) &&
      (data.data.text.include?("SEARCH completed")) 
  end,
  
  v(p(m.method('send_command'),'UID SEARCH OR (CC testme1 CC testme2) CC testme3')) do |mcaller, data|
      mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
      (data.data.class == Net::IMAP::ResponseText) &&
      (data.data.text.include?("SEARCH completed"))   
  end,
  p(m.method('delete'),"INBOX/cc"),  
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