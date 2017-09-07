#!/usr/bin/ruby -w
#
# = data/imap/within.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH WITHIN test cases
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
current.description = "IMAP Search WITH IN"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)


m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org
BCC: testmeREPLACEME@ruby-lang.org

Search on message REPLACEME
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
  p(m.method('create'),"INBOX/within"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/within",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.at(946702800+i*3600*24)) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/within"), 
  p(m.method('fetch'), 1..20, ['INTERNALDATE']),
  
  [  ["SEEN", "YOUNGER", "3600"],
     ["SEEN", "YOUNGER", "360000"], 
     ["SEEN", "OLDER", (Time.now - Time.at(946702800)).to_i + 3600]
  ].map do |x|
    [  SearchVerify.new(m, x, &IMAP::EmptyArray),
       UidsearchVerify.new(m, x, &IMAP::EmptyArray)
    ]
  end,  
  
    
  {  
      ["SEEN", "OLDER", "3600"] => (1..20).to_a, 
  }.sort.map do |x|
    [  
      SearchVerify.new(m, x[0], x[1]),      
    ]
  end,  
  
  p(m.method('delete'),"INBOX/within"),  
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