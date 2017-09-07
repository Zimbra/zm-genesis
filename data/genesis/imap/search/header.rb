#!/usr/bin/ruby -w
#
# = data/imap/header.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH header test cases
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
current.description = "IMAP Search Header test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesisREPLACEME@test.org, REPLACEME@hi.com
To: genesisREPLACEME@test.org
Cc: nothere@ruby-lang.org, REPLACEME@hi.com
Reply-to: replyREPLACEME@reply.net
Message-id: <1234.4567@whatever.com>
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
  
]

#
# Execution
#
current.action = [  
                  CreateAccount.new(testAccount.name,testAccount.password),
                  p(m.method('login'),testAccount.name,testAccount.password),
                  p(m.method('create'),"INBOX/header"),
                  
                  cb("Create 20 messages using append") {       
                    1.upto(20) { |i|
                      m.append("INBOX/header",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
                    }
                    "Done"
                  }, 
                  
                  p(m.method('examine'),"INBOX/header"),  
                  { %w[HEADER SUBJECT hello] => (z = (1..20).to_a),
                    %w[HEADER SUBJECT HELLO] => z,
                    %w[HEADER Message-id <1234.4567@whatever.com>] => z, #bug 42748
                    %w[HEADER Message-id 1235] => [],
                    %w[HEADER TO genesis3@test.org] => [3],
                    %w[HEADER FROM 7@hi.com] => (y = [7]),
                    %w[HEADER from 7@hi.com] => y,
                    %w[HEADER From 7@hi.com] => y,
                    %w[HEADER CC nothere@ruby-lang.org] => z   
                  }.sort.map do |x|
                    SearchVerify.new(m, x[0], x[1])
                  end,   
                  
                  { %w[HEADER Comments comment] => (z = (1..20).to_a),
                    %w[HEADER reply-to reply9@reply.net] => [9],
                    %w[HEADER Keywords keyword] => z, 
                    %w[HEADER References one] => z
                  }.map do |x|
                    SearchVerify.new(m, x[0], x[1])
                    
                  end,
                  #bug 42748 boundary case
                  %w[<> < > <<> <@> @].map do |x|
                    SearchVerify.new(m, "HEADER Message-id #{x}", [])
                  end
                    
                  
                  #p(m.method('delete'),"INBOX/header"),  
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
