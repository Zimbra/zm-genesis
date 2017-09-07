#!/usr/bin/ruby -w
#
# = data/imap/larger.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH larger test cases
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
current.description = "IMAP Search Larger test"

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
Reply-to: replyREPLACEME@reply.net
Message-id: 1234
In-reply-to: in-reply-toREPLACEME@reply.net
References: one
Comments: comment
Keywords: keyword

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
  p(m.method('create'),"INBOX/larger"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      outmessage = message+"anotherline\r\n"*i
      m.append("INBOX/larger",outmessage.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('examine'),"INBOX/larger"),      
  [  ["LARGER", "536"],
     ["LARGER", "537"],      
  ].map do |x|
    [  SearchVerify.new(m, x, &IMAP::EmptyArray),
       UidsearchVerify.new(m, x, &IMAP::EmptyArray)
    ]
  end, 
  
  { %w[LARGER 535] => [20],    
    %w[LARGER 0] => [20],    
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,
  
  [ %w[LARGER -1],
    %w[LARGER a],
    %w[LARGER, '02']
  ].map do |x|
    SearchVerify.new(m, x, &IMAP::FetchParseError)
  end,  
  
  v(p(m.method('uid_search'),'LARGER 535')) do |mcaller, data|    
    mcaller.pass = (data.class == Array) &&
      (data.size == 1) &&
      (data[0].class == Fixnum)
  end,  
  p(m.method('delete'),"INBOX/larger"),   
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