#!/usr/bin/ruby -w
#
# = data/imap/from.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH from test cases
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
current.description = "IMAP Search From test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesisREPLACEME@test.org, REPLACEME@hi.com
To: genesisREPLACEME@test.org
Cc: nothere@ruby-lang.org, REPLACEME@hi.com

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
  p(m.method('create'),"INBOX/from"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/from",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('examine'),"INBOX/from"),    
  [["FROM", "none"],
   ["FROM",'nothere']
  ].map do |x|
    SearchVerify.new(m, x, &IMAP::EmptyArray)
  end, 
   
  { ["FROM",'genesis1@test.org'] => (y = [1]),
    ["FROM",'1@hi.com'] => y,     
    ["FROM",'genesis1'] => y,
    ["NOT", "FROM",'genesis1'] => (2..9).to_a << 20,    
    ["OR", "FROM",'genesis1', "FROM", 'genesis2'] => [1, 2]
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,  
  
  v(cb("Complex SEARCH") do
      m.method('send_command').call('SEARCH OR (FROM genesis1 FROM genesis2) FROM genesis3')
      m.responses
    end) do |mcaller, data|
      mcaller.pass = (data.class == Hash) &&
        (data['SEARCH'][0][0] == 3)     
  end,
  
  v(cb("Complex UID SEARCH") do
      m.method('send_command').call('UID SEARCH OR (FROM genesis1 FROM genesis2) FROM genesis3')
      m.responses
    end) do |mcaller, data|
      mcaller.pass = (data.class == Hash) &&
        (data['SEARCH'][0][0].class == Fixnum)     
  end,  
  
  p(m.method('delete'),"INBOX/from"),  
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