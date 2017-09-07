#!/usr/bin/ruby -w
#
# = data/imap/search/recent.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH recent test cases
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
current.description = "IMAP Search Recent test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
m1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
m2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
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
  p(m.method('create'),"INBOX/recent"), 
  cb("Create 10 messages") {     
    0.upto(9) { |i|      
      sflags = ['DUMMY']
      if(i%2 ==0) 
        sflags = [:Seen]   
      end
      m.append("INBOX/recent",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
    }
    "Done"
  },
  p(m.method('logout')),
  p(m1.method('login'),testAccount.name,testAccount.password),
  cb("Create 10 messages") {     
    0.upto(9) { |i|      
      sflags = ['DUMMY']
      if(i%2 == 0) 
        sflags = [:Seen]
      end
      m1.append("INBOX/recent",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
    }
    "Done"
  },
  #So we have 20 messages with different states
  p(m1.method('select'),'INBOX/recent'),
  p(m1.method('search'),'RECENT'), 
  p(m1.method('search'),'NOT RECENT'),
  p(m1.method('search'),'NOT NOT RECENT'),   
  {   
    'RECENT' => (y= (1..20).to_a), 
    'NOT RECENT' => (z = (1..20).to_a - y),
    'NOT NOT RECENT' => y, 
  }.sort.map do |x|
     SearchVerify.new(m1, x[0], x[1])
  end,  
  p(m1.method('examine'),"INBOX/recent"),   
  UidsearchVerify.new(m1, 'NOT NOT RECENT', 0),  
  # new connection should not see any 
  p(m2.method('login'),testAccount.name,testAccount.password),
  p(m2.method('select'),'INBOX/recent'),
  {   
    'NOT RECENT' => (y= (1..20).to_a), 
    'RECENT' => (z = (1..20).to_a - y),
    'NOT NOT RECENT' => z, 
  }.sort.map do |x|
     SearchVerify.new(m2, x[0], x[1])
  end,  
  p(m2.method('logout')),
  p(m1.method('delete'),'INBOX/recent'),
  p(m1.method('logout')),  
]

#
# Tear Down
#
current.teardown = [   
  p(m.method('disconnect')),   
  p(m1.method('disconnect')),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end