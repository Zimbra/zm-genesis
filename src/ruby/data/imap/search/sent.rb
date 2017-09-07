#!/usr/bin/ruby -w
#
# = data/imap/search/sent.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH sent test cases
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
current.description = "IMAP Search SENT test"

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
Sent: REPLACEDATE

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
  p(m.method('create'),"INBOX/senttest"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      outmessage = message.gsub(/REPLACEME/, i.to_s).gsub(/REPLACEDATE/, Time.at(946702800+i*3600*24).to_s)
      m.append("INBOX/senttest", outmessage,[:Seen], Time.now) 
    }
    "Done"
  }, 
  
  p(m.method('select'),'INBOX/senttest'),
  [  'SENTBEFORE 01-Jan-2000',
     'SENTBEFORE 02-Jan-2000',
     'SENTBEFORE 20-Jan-2000',     
     'SENTBEFORE 21-Jan-2000',
     'SENTBEFORE 21-Jan-2002',    
     'SENTBEFORE 31-Dec-1999',
     'SENTON 01-Jan-2000',
     'SENTON 02-Jan-2000',
     'SENTON 20-Jan-2000',     
     'SENTON 21-Jan-2000',
     'SENTON 21-Jan-2002',    
     'SENTON 31-Dec-1999',
  ].map do |x|
    [  SearchVerify.new(m, x, &IMAP::EmptyArray),
       UidsearchVerify.new(m, x, &IMAP::EmptyArray)
    ]
  end,
    
  {    
    'SENTSINCE 31-Dec-1999' => (y= (1..20).to_a),
    'SENTSINCE 01-Jan-2000' => y,
    'SENTSINCE 02-Jan-2000' => y,
    'SENTSINCE 20-Jan-2000' => y,
    'SENTSINCE 21-Jan-2000' => y,
    'SENTSINCE 21-Jan-2002' => y,
    
  }.sort.map do |x|
     [ SearchVerify.new(m, x[0], x[1]),
       UidsearchVerify.new(m, x[0], x[1].size)
     ]
  end,      
  p(m.method('delete'),"INBOX/senttest"),  
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