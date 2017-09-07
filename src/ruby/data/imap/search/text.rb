#!/usr/bin/ruby -w
#
# = data/imap/search/text.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH text test cases
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
current.description = "IMAP Search Text test"

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

Search body message REPLACEME
  Orange 
    Apple
      Pear.
Garbage.
me. "Quoted"
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
  p(m.method('create'),"INBOX/text"),
  cb("Create 10 messages using append") {       
    1.upto(10) { |i|
      m.append("INBOX/text",message.gsub(/REPLACEME/,i.to_s),[:Deleted], Time.now)
      #SendMail.new(testAccount.name, message.gsub(/REPLACEME/,i.to_s)).run
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/text"), 
  {    
    ["TEXT","genesis"] => (y = (1..10).to_a),
    ["TEXT","hello"] => y,
    ["TEXT","ear"] => (z = []),
    ["TEXT","Search"] => y,
    ["TEXT","SEARCH"] => y,
    ["TEXT","1"] => [1, 10],
    ["OR", "TEXT", "1", "TEXT", "2"] => [1, 2, 10],
    ["NOT", "OR", "TEXT", "1", "TEXT", "2"] => y - [1, 2, 10],
    ["TEXT", "1", "TEXT", "2"] => z,
    'NOT (OR TEXT 1 TEXT 2)' => (3..9).to_a,
    ["TEXT","Orange"] => y,
    ["TEXT","Apple"] => y,
    ["TEXT","Pear"] => y,
    ["TEXT","Garbage"] => y,
    ["TEXT","Garbage."] => y,
    ["TEXT","Quoted"] => y,
    ["TEXT",'"Quoted"'] => y,
    ["TEXT","so#{1.chr}so"] => z,
    ["TEXT", "1", "TEXT", "1"] => [1, 10]    
  }.sort { |a, b| a[1] <=> b[1] }.map do |x|
    if (x[1].size == 0)
      [SearchVerify.new(m, x[0], &IMAP::EmptyArray), 
        UidsearchVerify.new(m, x[0], &IMAP::EmptyArray)
      ]
    else
      [SearchVerify.new(m, x[0], x[1]),
        UidsearchVerify.new(m, x[0], x[1].size)
      ]
    end     
  end,  
  p(m.method('fetch'),1,["UID"]),
  p(m.method('delete'),"INBOX/text"),     
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