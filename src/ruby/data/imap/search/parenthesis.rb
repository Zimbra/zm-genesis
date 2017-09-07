#!/usr/bin/ruby -w
#
# = data/imap/search/parenthesis.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH parenthesis test cases
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
current.description = "IMAP Search Parenthesis test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

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
  p(m.method('create'),"INBOX/parenthesis"),
  cb("Create 20 messages using append") {       
    1.upto(20) { |i|
      m.append("INBOX/parenthesis",message.gsub(/REPLACEME/,i.to_s),[:Draft], Time.now) 
    }
    "Done"
  }, 

  p(m.method('examine'),"INBOX/parenthesis"),    
  {   
    '(NOT DELETED) (SINCE 25-Jul-2005)' => (y= (1..20).to_a), 
    '(ALL)' => y,
    '((ALL))' => y,
    'OR ALL (ALL)' => y,
    'OR (ALL) ALL' => y
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,   
  p(m.method('delete'),"INBOX/parenthesis"),  
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