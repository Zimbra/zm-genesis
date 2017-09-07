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
# zmmailboxmove test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
  require 'engine/simple'
  require 'data/multinode/setup'
  Engine::Simple.new(Model::TestCase.instance, false).run  
end 

require "model"
require "action/block"

require "action/mailboxmove" 
require "action/verify"
require "action/zmprov"
require "action/decorator"
require "action/zmmailbox"
require 'action/runcommand' 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
require 'timeout'
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Share Folder IDLE test"

nameOne = 'imshare1'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameTwo = 'imshare2'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

origHost = Model::TARGETHOST
destHost = Model::TARGETHOST.findService(:service)[-1]
proxy = (Model::TARGETHOST.findService(:imapproxy).first rescue origHost) || origHost

nameOneAccount = origHost.cUser(nameOne, Model::DEFAULTPASSWORD)
nameTwoAccount = origHost.cUser(nameTwo, Model::DEFAULTPASSWORD)

mimap = d
mimap2 = d

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello REPLACEME
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
EOF

mailbox = "INBOX/share"


include Action

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
                  cb("Set ACL Account Two") {               
                    mimap2.object = Net::IMAP.new(destHost, *destHost.imap)
                    mimap2.login(nameTwoAccount.name, nameTwoAccount.password)
                    mimap2.create(mailbox)
                    mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mailbox)
                    mimap2.method('send_command').call("GETACL %s"%mailbox)
                    mimap2.append(mailbox,message.gsub(/REPLACEME/, nameOneAccount.name),[], Time.now)
                    mimap2.logout
                    mimap2.disconnect
                  },  
                  
                  v(cb("Copy from Account Two to Account One") {
                      mimap.object = Net::IMAP.new(origHost, *origHost.imap)
                      mimap.login(nameOneAccount.name, nameOneAccount.password)
                      mimap.create('INBOX/copyto')
                      mimap.select("/home/#{nameTwoAccount.name}/%s"%mailbox)  
                      result = false
                      Timeout::timeout(20) {
                        mimap.method('put_string').call("A1 IDLE\r\n") 
                        sleep(5)
                        mimap.method('put_string').call("DONE\r\n")
                        result = true
                      }
                      result
                    }) do |mcaller, data|
                    mcaller.pass = data
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
