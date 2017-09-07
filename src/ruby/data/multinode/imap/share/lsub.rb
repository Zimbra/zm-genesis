#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Zimbra
#
# imap share folder lsub test

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
current.description = "Share folders lsub test"

nameOne = 'imshare1'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameTwo = 'imshare2'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameThree = 'imshar3'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

origHost = Model::TARGETHOST
destHost = Model::TARGETHOST.findService(:service)[-1]
proxy = (Model::TARGETHOST.findService(:imapproxy).first rescue origHost) || origHost
mta = (Model::TARGETHOST.findService(:mta).first rescue origHost) || origHost

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

mailbox = ["INBOX/share", "INBOX/share2", "INBOX/share/subshare"]

include Action

#Net::IMAP.debug=true

#
# Setup
#
current.setup = []
#
# Execution
#
current.action = [    
  Action::CreateAccount.new(nameOneAccount.name,nameOneAccount.password, 'zimbraMailHost', origHost.to_s),
  Action::CreateAccount.new(nameTwoAccount.name,nameTwoAccount.password, 'zimbraMailHost', destHost.to_s),
  Action::CreateAccount.new(nameThreeAccount.name,nameThreeAccount.password, 'zimbraMailHost', origHost.to_s),                   
  cb("Set ACL Account Two") {               
    mimap2.object = Net::IMAP.new(destHost, *destHost.imap)
    mimap2.login(nameTwoAccount.name, nameTwoAccount.password)
    mailbox.map do |mlb|
      mimap2.create(mlb)
      mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mlb)
      mimap2.method('send_command').call("GETACL %s"%mlb)
      mimap2.append(mlb,message.gsub(/REPLACEME/, nameOneAccount.name),[:Deleted], Time.now)
    end
    mimap2.logout
    mimap2.disconnect
  },  
  cb("Set ACL Account Three") {               
    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
    mimap2.login(nameThreeAccount.name, nameThreeAccount.password)
    mailbox.map do |mlb|
      mimap2.create(mlb)
      mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mlb)
      mimap2.method('send_command').call("GETACL %s"%mlb)
      mimap2.append(mlb,message.gsub(/REPLACEME/, nameOneAccount.name),[:Deleted], Time.now)
    end
    mimap2.logout
    mimap2.disconnect
  },  
  cb("Log into account one") do
    mimap.object = Net::IMAP.new(origHost, *origHost.imap)
    mimap.login(nameOneAccount.name, nameOneAccount.password)
  end,
  
  # subscribe to the shared folders
  mailbox.map do |x| 
    ["/home/#{nameTwoAccount.name}", "/home/#{nameThreeAccount.name}"].map do |y|
      SubscribeVerify.new(mimap, File.join(y, x))
    end
  end,
  
  # check LSUB on shared folders
  [nameTwoAccount.name, nameThreeAccount.name].map do |curName|
    v(cb("Lsub cross server") do
        mimap.object = Net::IMAP.new(origHost, *origHost.imap)
        mimap.login(nameOneAccount.name, nameOneAccount.password)
        mimap.lsub("/home/%s/INBOX"%curName, "*")
      end) do |mcaller, data|
      mcaller.pass = data.first.class == Net::IMAP::MailboxList &&
        data.first[:name].match("/home/%s"%curName) &&
        data.size == mailbox.size
    mimap.logout
    mimap.disconnect
    end
  end,
  
  # bug 61435
  # delete one accounts, change shared folders on the other
  DeleteAccount.new(nameTwoAccount.name),
  cb("Modify shared folders") do              
    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
    mimap2.login(nameThreeAccount.name, nameThreeAccount.password)
    mimap2.delete(mailbox[2])
    mimap2.rename(mailbox[1], mailbox[1] + "renamed")
    mimap2.logout
    mimap2.disconnect
  end,
  
  # nothing should change for the slave client
  [nameTwoAccount.name, nameThreeAccount.name].map do |curName|
    v(cb("Lsub cross server") do
        mimap.object = Net::IMAP.new(origHost, *origHost.imap)
        mimap.login(nameOneAccount.name, nameOneAccount.password)
        mimap.lsub("/home/%s/INBOX"%curName, "*")
      end) do |mcaller, data|
      mcaller.pass = data.first.class == Net::IMAP::MailboxList &&
        data.first[:name].match("/home/%s"%curName) &&
        data.size == mailbox.size
    mimap.logout
    mimap.disconnect
    end
  end,
]

#
# Tear Down
#
current.teardown = [
  DeleteAccount.new(nameOneAccount.name),
  DeleteAccount.new(nameTwoAccount.name),
  DeleteAccount.new(nameThreeAccount.name)
]

if($0 == __FILE__)
  Engine::Simple.new(Model::TestCase.instance).run  
end
