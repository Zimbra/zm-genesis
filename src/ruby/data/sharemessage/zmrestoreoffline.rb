#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Test to verify Bug 27617 - Zmrestoreoffline: exception raised on accounts with share messages
#
#
# Global variable declaration
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end


require "action"
require "action/verify"
require "action/runcommand"
require "action/waitqueue"
require "action/zmcontrol"
require "action/zmprov"
require "action/zmrestore"
require "action/zmamavisd"
require "action/zmrestoreoffline"
require "model"

include Action
#Test plan

def noError
  proc do |mcaller, data|
    mcaller.pass =
      (data[0] == 0)
  end
end



#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Bug 27617 Verification #{File.basename(__FILE__,'.rb')}"
name1 = 'cli1'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name2 = 'cli2'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount1 = Model::TARGETHOST.cUser(name1, Model::DEFAULTPASSWORD)
testAccount2 = Model::TARGETHOST.cUser(name2, Model::DEFAULTPASSWORD)
recipientList = [testAccount1,testAccount2]
admin = Model::TARGETHOST.cUser("admin",Model::DEFAULTPASSWORD)


backupA = Action::Fullbackup.new('-a', 'all')
backupB = Action::Fullbackup.new('-a', "#{testAccount1.name} #{testAccount2.name}")

message = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACEME/, "#{testAccount1.name}, #{testAccount2.name}")
Subject: restoretest MARKME
From: genesis@zimbra.com
To: REPLACEME

This message is for restoretest MARKME
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

  CreateAccount.new(testAccount1.name,testAccount1.password), #test account

  CreateAccount.new(testAccount2.name,testAccount2.password), #test account

  SendMail.new(recipientList, message.gsub(/MARKME/, 'Restore Test msg 1')),

  WaitQueue.new,

  backupA,

  v(ZMMailboxdctl.new('stop')) do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('Stopping mailboxd...done.')
  end,

  v(ZMRestoreOffline.new('-a','all')) do |mcaller,data|
        mcaller.pass = data[0]==0 && data[1].include?('mailboxd is not running')
  end,

  v(ZMMailboxdctl.new('start')) do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('Starting mailboxd...done.')
  end,

  cb("Sleep 60 seconds", 120) do
   Kernel.sleep(60)
  end,

  backupB,

  v(ZMMailboxdctl.new('stop')) do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('Stopping mailboxd...done.')
  end,

  v(ZMRestoreOffline.new('-a',"#{testAccount1.name} #{testAccount2.name}" )) do |mcaller,data|
        mcaller.pass = data[0]==0 && data[1].include?('mailboxd is not running')
  end,

  v(ZMMailboxdctl.new('start')) do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('Starting mailboxd...done.')
  end,

  v(ZMMailboxdctl.new('status')) do |mcaller,data|
    mcaller.pass = data[0]==0 && data[1].include?('mailboxd is running.')
  end,

]

current.teardown = [
]


if __FILE__ == $0
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end