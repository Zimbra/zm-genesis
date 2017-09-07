#!/usr/bin/ruby -w
#
# = data/imap/bcc.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH bcc test cases
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
current.description = "IMAP Search BCC test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org
BCC: testmeREPLACEME@ruby-lang.org

Search message REPLACEME
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
  p(m.method('create'),"INBOX/bcc"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/bcc",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('examine'),"INBOX/bcc"),   
  SearchVerify.new(m, ["BCC", "none"], &IMAP::EmptyArray),
  SearchVerify.new(m, ["BCC", "test@ruby-lang.org"], &IMAP::EmptyArray),  
  SearchVerify.new(m, ["BCC", "testme2@ruby-lang.org"], [2]), 
  UidsearchVerify.new(m, ["BCC","test1@ruby-lang.org"], 0),
  p(m.method('delete'),"INBOX/bcc"),  
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