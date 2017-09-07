#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# IMAP append max size test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/decorator"
require "action/zmprov"
require "action/zmcontrol"
require "action/zmamavisd"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Append Size Test Bug 51902"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = d
#
# Setup
#
current.setup = [
  
]

message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, testAccount.name)
Message-ID: <45DF8D60.70202@boris-d600.test.com>
Date: Fri, 23 Feb 2007 16:57:04 -0800
From: user1 <user1@boris-d600.test.com>
User-Agent: Thunderbird 1.5.0.9 (Windows/20061207)
MIME-Version: 1.0
To:  user1@boris-d600.test.com
Subject: attachment 3
 
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
abcdefghijklmnopqrstuvwxyz
EOF
#
# Execution
#
#Net::IMAP.debug = true
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password), 
  ZMProv.new("mcf", "zimbraMtaMaxMessageSize", "100"),       
  ZMMailboxdctl.new("stop"),
  ZMMailboxdctl.new("start"),  
  cb("login") do
    sleep(5)
    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mimap.login(testAccount.name, testAccount.password)
  end,
  # Simple append command
  cb("Create mail box") do
    mimap.create("INBOX/append")
  end,
  v(
    cb("This message should be rejected due to size limitation") do
      mimap.append("INBOX/append", message, [:Answered, :Deleted, :Draft, :Flagged, :Seen])
      end
    ) do |caller, data|
     caller.pass = (data.class == Net::IMAP::BadResponseError && data.message =~ /maximum literal size exceeded/) ||
                   (data.class == Net::IMAP::NoResponseError && data.message =~ /maximum message size exceeded/)
  end,
  
  cb("Clean up") do
    mimap.logout
    mimap.disconnect
  end,
  ZMProv.new("mcf", "zimbraMtaMaxMessageSize", "10240000"),
  ZMMailboxdctl.new("stop"),
  ZMMailboxdctl.new("start"),                  
]

#
# Tear Down
#
current.teardown = [      
 
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
