#!/usr/bin/ruby -w
#
# = data/imap/search/sequence.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH sequence test cases
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
current.description = "IMAP Search Sequence test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
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
  p(m.method('create'),"INBOX/sequence"), 
  cb("Create 20 messages") { 
    1.upto(20) { |i|
      m.append("INBOX/sequence",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/sequence"), 
  {    
    '*' => [20],
    '*:*' => [20],
    'ALL' => (y = (1..20).to_a),
    '2,4:7,9,12:*' => [2,9] + (4..7).to_a + (z = (12..20).to_a),
    '2 2' => [2],
    'NOT 12:*' => y - z,
    'NOT NOT 12:*' => z,
    'OR 1 20' => [1, 20],
    '15' => [15],
    'NOT 15' => y - [15],
    '1:*' => y    
  }.sort.map do |x|
     [ SearchVerify.new(m, x[0], x[1]),
       UidsearchVerify.new(m, x[0], x[1].size)
     ]
  end,   
  SearchVerify.new(m, '1:10000', (1..20).to_a),
  UidsearchVerify.new(m, '1:10000', 20),
  p(m.method('delete'),"INBOX/sequence")
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