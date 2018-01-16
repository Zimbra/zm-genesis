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
current.description = "Copy between share folders"

nameOne = 'imshare1'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameTwo = 'imshare2'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
nameThree = 'imshar3'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

origHost = Model::TARGETHOST
#destHost = Model::TARGETHOST.findService(:service)[-1]
#proxy = (Model::TARGETHOST.findService(:imapproxy).first rescue origHost) || origHost
#runThisTest = (origHost != destHost)

nameOneAccount = origHost.cUser(nameOne, Model::DEFAULTPASSWORD)
nameTwoAccount = origHost.cUser(nameTwo, Model::DEFAULTPASSWORD)
nameThreeAccount = origHost.cUser(nameThree, Model::DEFAULTPASSWORD)

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
                  Action::CreateAccount.new(nameOneAccount.name,nameOneAccount.password),
                  Action::CreateAccount.new(nameTwoAccount.name,nameTwoAccount.password),
                  Action::CreateAccount.new(nameThreeAccount.name,nameThreeAccount.password),                   
                  cb("Set ACL Account Two") {               
                    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
                    mimap2.login(nameTwoAccount.name, nameTwoAccount.password)
                    mimap2.create(mailbox)
                    mimap2.method('send_command').call("SETACL %s #{nameOneAccount.name} lrswickxteda"%mailbox)
                    mimap2.method('send_command').call("GETACL %s"%mailbox)
                    mimap2.append(mailbox,message.gsub(/REPLACEME/, nameOneAccount.name),[], Time.now)
                    mimap2.logout
                    mimap2.disconnect
                  },  
                  cb("Set ACL Account Three") {               
                    mimap2.object = Net::IMAP.new(origHost, *origHost.imap)
                    mimap2.login(nameThreeAccount.name, nameThreeAccount.password)
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
                      result = nil
                      Timeout::timeout(20) {
                        result = mimap.copy(1, 'INBOX/copyto')
                      }
                      mimap.logout
                      mimap.disconnect
                      result
                    }) do |mcaller, data|
                    mcaller.pass = data.class == Net::IMAP::TaggedResponse && 
                      data['raw_data'].include?('OK')
                  end,
                  v(cb("Copy from Account Two to Account Three") {
                      mimap.object = Net::IMAP.new(origHost, *origHost.imap)
                      mimap.login(nameOneAccount.name, nameOneAccount.password)
                      mimap.select("/home/#{nameTwoAccount.name}/%s"%mailbox)
                      result = nil
                      Timeout::timeout(20) {
                        result = mimap.copy(1, "/home/#{nameThreeAccount.name}/%s"%mailbox)
                      }
                      mimap.logout
                      mimap.disconnect
                      result
                    }) do |mcaller, data|
                    mcaller.pass = data.class == Net::IMAP::TaggedResponse && 
                      data['raw_data'].include?('OK')
                  end,
                  v(cb("Copy from Account Two to Account Two") {
                      mimap.object = Net::IMAP.new(origHost, *origHost.imap)
                      mimap.login(nameOneAccount.name, nameOneAccount.password)
                      mimap.select("/home/#{nameTwoAccount.name}/%s"%mailbox)
                      result = nil
                      Timeout::timeout(20) {
                        result = mimap.copy(1, "/home/#{nameTwoAccount.name}/%s"%mailbox)
                      }
                      mimap.logout
                      mimap.disconnect
                      result
                    }) do |mcaller, data|
                    mcaller.pass = data.class == Net::IMAP::TaggedResponse && 
                      data['raw_data'].include?('OK')
                  end,
                  v(cb("Select") {
                      mimap.object = Net::IMAP.new(origHost, *origHost.imap)
                      mimap.login(nameOneAccount.name, nameOneAccount.password)
                      result = nil
                      Timeout::timeout(20) {
                        mimap.select('INBOX/copyto')
                        result = mimap.fetch(1,"BODY[]")
                      }
                      mimap.logout
                      mimap.disconnect
                      result
                    }) do |mcaller, data|
                    mcaller.pass = data.first.class == Net::IMAP::FetchData &&
                      data.first['attr']['BODY[]'].include?(nameOneAccount.name) rescue false
                  end,
                  
                 ]

#
# Tear Down
#
current.teardown = []

if($0 == __FILE__)
  Engine::Simple.new(Model::TestCase.instance).run  
end
