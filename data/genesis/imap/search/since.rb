#!/usr/bin/ruby -w
#
# = data/imap/search/since.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH since test cases
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
current.description = "IMAP Search SINCE test"

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
  p(m.method('create'),"INBOX/since"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/since",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.at(946702800+i*3600*24)) 
    }
    "Dsincee"
  }, 
  p(m.method('select'),"INBOX/since"), 
  p(m.method('fetch'), 1..20, ['INTERNALDATE']),
     
  [  'SINCE 21-Jan-2000',
     'SINCE 21-Jan-2002',
  ].map do |x|
    [  SearchVerify.new(m, x, &IMAP::EmptyArray),
       UidsearchVerify.new(m, x, &IMAP::EmptyArray)
    ]
  end,
  
  {    
    'SINCE 31-Dec-1999' => (y= (1..20).to_a),
    'SINCE 01-Jan-2000' => y,
    'SINCE 02-Jan-2000' => y - [1],
    'SINCE 20-Jan-2000' => [20],   
    'NOT SINCE 20-Jan-2000' => (1..19).to_a    
  }.sort.map do |x|
     [ SearchVerify.new(m, x[0], x[1]),
       UidsearchVerify.new(m, x[0], x[1].size)
     ]
  end,    
  
  p(m.method('delete'),"INBOX/since"),  
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