#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# imap share folder status test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
  require 'engine/simple'
  require 'data/multinode/setup'
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 

require "model"

require "action/block"
require "action/decorator"
require "action/sendmail"
require "action/verify"
require "action/zmmailbox"
require "action/zmprov"
require 'action/runcommand' 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Share folders status test"

nameOne = 'imshare1'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameTwo = 'imshare2'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameThree = 'imshar3'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

origHost = Model::TARGETHOST
#destHost = Model::TARGETHOST.findService(:service)[-1]
#proxy = (Model::TARGETHOST.findService(:imapproxy).first rescue origHost) || origHost
#mta = (Model::TARGETHOST.findService(:mta).first rescue origHost) || origHost

nameOneAccount = origHost.cUser(nameOne, Model::DEFAULTPASSWORD)
nameTwoAccount = origHost.cUser(nameTwo, Model::DEFAULTPASSWORD)
nameThreeAccount = origHost.cUser(nameThree, Model::DEFAULTPASSWORD)

mimap = d
mimap2 = d

message =  <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org
BCC: REPLACEME@ruby-lang.org

Search body message REPLACEME
  Orange 
    Apple
      Pear.
Garbage.
me. "Quoted"
EOF

mailbox = "INBOX/share"
flags = ["MESSAGES", "RECENT","UNSEEN", "UIDVALIDITY"]


include Action

#
# Setup
#
current.setup = []
#
# Execution
#
current.action = [    
                  Action::CreateAccount.new(nameOneAccount.name,nameOneAccount.password),
                  Action::CreateAccount.new(nameTwoAccount.name,nameTwoAccount.password),
                  Action::CreateAccount.new(nameThreeAccount.name,nameThreeAccount.password),                   
                  cb("Set ACL Account Two") {               
                    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
                    mimap2.login(nameTwoAccount.name, nameTwoAccount.password)
                    mimap2.create(mailbox)
                    mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mailbox)
                    mimap2.method('send_command').call("GETACL %s"%mailbox)
                    mimap2.append(mailbox,message.gsub(/REPLACEME/, nameOneAccount.name),[:Deleted], Time.now)
                    mimap2.logout
                    mimap2.disconnect
                  },  
                  cb("Set ACL Account Three") {               
                    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
                    mimap2.login(nameThreeAccount.name, nameThreeAccount.password)
                    mimap2.create(mailbox)
                    mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mailbox)
                    mimap2.method('send_command').call("GETACL %s"%mailbox)
                    mimap2.append(mailbox,message.gsub(/REPLACEME/, nameOneAccount.name),[:Deleted], Time.now)
                    mimap2.logout
                    mimap2.disconnect
                  },  
                  cb("Log into account one") do
                    mimap.object = Net::IMAP.new(origHost, *origHost.imap)
                    mimap.login(nameOneAccount.name, nameOneAccount.password)
                  end,
                  [mailbox].map do |x| 
                    ["/home/#{nameTwoAccount.name}", "/home/#{nameTwoAccount.name}"].map do |y|
                      StatusVerify.new(mimap, File.join(y, x), flags)
                    end
                  end, 
                  ["INBOX", "Trash"].map do |x| 
                    ["/home/#{nameTwoAccount.name}", "/home/#{nameTwoAccount.name}"].map do |y|
                      StatusVerify.new(mimap, File.join(y, x), flags, &IMAP::StatusFailed)
                    end
                  end, 
                  cb("Clean Up") do
                    mimap.logout
                    mimap.disconnect
                  end
                 ]

#
# Tear Down
#
current.teardown = []

if($0 == __FILE__)
  Engine::Simple.new(Model::TestCase.instance).run  
end
