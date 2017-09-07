#!/usr/bin/ruby -w
#
# = action/copy.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP copy test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Copy test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
#name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
m1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello REPLACEME
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
  p(m.method('create'),"INBOX/copyfrom"), 
  cb("Create 10 messages") {     
    0.upto(10) { |i|      
      sflags = ['DUMMY']
      if(i%2 ==0) 
        sflags = [:Seen]   
      end
      m.append("INBOX/copyfrom",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
    }
    "Done"
  },
  p(m.method('logout')),
  p(m1.method('login'),testAccount.name,testAccount.password),
  cb("Create 10 messages") {     
    0.upto(10) { |i|      
      sflags = ['DUMMY']
      if(i%2 == 0) 
        sflags = [:Seen]
      end
      m1.append("INBOX/copyfrom",message.gsub(/REPLACEME/,(i + 11).to_s),sflags, Time.now) 
    }
    "Done"
  },
 
  #So we have 20 messages with different states
  p(m1.method('create'),'INBOX/copyto'),
  p(m1.method('select'),'INBOX/copyfrom'),
  p(m1.method('fetch'),1..20, 'ALL'), 
  p(Kernel.method('sleep'),5), 
  CopyVerify.new(m1, 1..20,'INBOX/copyto'),   
  p(m1.method('select'),'INBOX/copyto'),
  FetchVerify.new(m1, 1..1,'RFC822.TEXT', 'Sequence message 0'),
  FetchVerify.new(m1, 2..2,'RFC822.TEXT', 'Sequence message 1'),
  FetchVerify.new(m1, 19..19,'RFC822.TEXT', 'Sequence message 18'),
  FetchVerify.new(m1, 20..20,'RFC822.TEXT', 'Sequence message 19'),
  FetchVerify.new(m1, 1..1,'RFC822.HEADER', 'hello 0'),
  FetchVerify.new(m1, 2..2,'RFC822.HEADER', 'hello 1'),
  FetchVerify.new(m1, 19..19,'RFC822.HEADER', 'hello 18'),
  FetchVerify.new(m1, 20..20,'RFC822.HEADER', 'hello 19'),
  
  v(
    cb("Examine") {
      m1.examine('INBOX/copyto')
      m1.responses["EXISTS"][-1]
    }
  ) { |mcaller, data|
    mcaller.pass = (data.to_i == 20)
  },   
  p(m1.method('fetch'),1..20, 'ALL'), 
  # If destination doesn't exist it should err
  p(m1.method('delete'),'INBOX/copyfrom'),
  p(m1.method('create'),'INBOX/copyfrom'), 
  CopyVerify.new(m1, (1..-1),'INBOX/copyfrom'), 
  CopyVerify.new(m1, (1..-1),'INBOX/nothere', &IMAP::CopyFailed), 
  CopyVerify.new(m1, (1..-1),'Contacts', &IMAP::CopyFailed), 
  CopyVerify.new(m1, (1..-1),'Drafts'), 
  CopyVerify.new(m1, (1..-1),'Junk'),
  p(m1.method('delete'),'INBOX/copyfrom'),
  p(m1.method('delete'),'INBOX/copyto'),
  p(m1.method('logout'))
   
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