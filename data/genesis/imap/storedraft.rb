#!/usr/bin/ruby -w
#
# = action/store.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP rename test cases
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
current.description = "IMAP Store Draft delete test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
mFolder = 'INBOX/storedelete'
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
   CreateAccount.new(testAccount.name,testAccount.password) 
]
   
 
#
# Execution
#
current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),mFolder), 
  cb("Create 1 messages") {     
    0.upto(0) { |i|    
      m.append(mFolder,message.gsub(/REPLACEME/,i.to_s), [], Time.now)    
      "Done"
    }
  }, 
  p(m.method('select') ,mFolder),   
  # empty store flag is acceptable
  StoreVerify.new(m, 1, "-FLAGS", [:Draft], []),  
  p(m.method('fetch'), 1, "FLAGS"),  
   
  p(m.method('select'), mFolder),
  p(m.method('delete'), mFolder),
  p(m.method('logout'))
   
]

#
# Tear Down
#
current.teardown = [
  p(m.method('disconnect')),
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
