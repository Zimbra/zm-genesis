#!/usr/bin/ruby -w
#
# = data/imap/all.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH all test cases
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
current.description = "IMAP Search ALL test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

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
  p(m.method('create'),"INBOX/all"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/all",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/all"),  
  SearchVerify.new(m, ["ALL"], (1..20).to_a),  
  
  #TODO fix inconsistency, the problem is figuring out the correctness of UID
  # Current verification for UID Search is pretty weak
  UidsearchVerify.new(m, ["ALL"], 20),  
  SearchVerify.new(m, ["NOT", "ALL"], &IMAP::EmptyArray), 
  UidsearchVerify.new(m, ["NOT", "ALL"], 0),   
  SearchVerify.new(m, ["ALL", "ALL"], (1..20).to_a),  
  v(p(m.method('send_command'),'SEARCH (ALL)')) do |mcaller, data|
    mcaller.pass = (data.class == Net::IMAP::TaggedResponse) && data.data.text.include?('SEARCH completed')
  end,
  p(m.method('delete'),"INBOX/all"),   
  
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