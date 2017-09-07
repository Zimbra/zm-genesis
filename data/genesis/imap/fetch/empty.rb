#!/usr/bin/ruby -w
#
# = data/imap/fetch/boundry.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP FETCH empty test cases
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
current.description = "IMAP Fetch Mime test"

name = 'ifetch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF
Date: Thu, 07 Aug 2008 10:47:41 -0400
From: Josh Freed <josh@fakeemail.com>
MIME-Version: 1.0
To: nothing@nowhere.com
Subject: Trying to make a crash
Content-Type: multipart/mixed;
 boundary="------------070009080906060400030707"

This is a multi-part message in MIME format.
--------------070009080906060400030707
Content-Type: text/plain; charset=ISO-8859-1; format=flowed
Content-Transfer-Encoding: 7bit


--------------070009080906060400030707--
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
  p(m.method('create'),"INBOX/EMPTY"),
  cb("Create message using append") {       
    1.upto(1) { |i|
      m.append("INBOX/EMPTY",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  },   
  {'BODY[1]' => '' }.sort { |a, b| a[1].to_s <=> b[1].to_s }.map do |x|
      IMAP.genFetchAction([Model::TARGETHOST, Model::IMAPSSL, true], testAccount, 'INBOX/EMPTY', x) 
  end,  
  p(m.method('delete'),"INBOX/EMPTY"),  
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
