#!/usr/bin/ruby -w
#
# = data/imap/search/subject.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH subject test cases
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
current.description = "IMAP Search SUBJECT test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello there REPLACEME
 multilineREPLACEME well
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
  p(m.method('create'),"INBOX/subject"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/subject",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  },
   
  p(m.method('examine'),"INBOX/subject"), 
  {    
    ["SUBJECT","none"] => (z = []),
    ["SUBJECT",'genesis1@test.org'] => z,
    ["SUBJECT",'1@hi.com'] => z,
    ["SUBJECT",'nothere'] => z,   
    ["SUBJECT",'genesis1'] => z,
    ["SUBJECT",'hello there 1'] => [1] + (10..19).to_a,
    ["SUBJECT",'HELLO THERE 1'] => [1] + (10..19).to_a,
    ["SUBJECT",'multiline1'] => [1] + (10..19).to_a,
    ["SUBJECT",'well'] => (1..20).to_a,
    ["NOT", "SUBJECT",'1'] => (2..9).to_a << 20,
    ["OR", "SUBJECT",'1', "SUBJECT", '2'] => [1, 2] + (10..20).to_a,
    'OR (SUBJECT 1 SUBJECT 2) SUBJECT 3' => [3]        
  }.sort { |a, b| a[1] <=> b[1] }.map do |x|
    if (x[1].size == 0)
      [SearchVerify.new(m, x[0], &IMAP::EmptyArray), 
        UidsearchVerify.new(m, x[0], &IMAP::EmptyArray)]
    else
      [SearchVerify.new(m, x[0], x[1]),
        UidsearchVerify.new(m, x[0], x[1].size)]
    end     
  end,  
  
  p(m.method('delete'),"INBOX/subject"),  
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