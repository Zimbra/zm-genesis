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
#  Test case for deleteAccount verification. verify that account is deleted and the blob directory for account is also deleted (Bug 26905)

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/waitqueue"
require "action/zmprov"
require "model"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for deleteAccount"
nNow = Time.now.to_i.to_s
nMount = File.join(Command::ZIMBRAPATH, 'delete_blob'+nNow)
name = 'deleteAccount'+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name,  Model::DEFAULTPASSWORD)

message = <<EOF.gsub(/\n/, "\r\n")
Subject: restoreabort
From: genesis@test.org
To: REPLACEME

This message is for MARKINDEX
This is for delete blob test
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

   RunCommand.new('/bin/mkdir','root',nMount),
   RunCommand.new('/bin/chown','root','zimbra', nMount),
   RunCommand.new('/bin/chgrp','root','zimbra', nMount),


  #Create Accounts
  CreateAccount.new(testAccount.name, testAccount.password),
  #Send emails
  cb("Send Emails", 600) do
    outMessage = message.gsub(/REPLACEME/,testAccount.name).gsub(/MARKINDEX/, testAccount.name)
    1.upto(3) do
      Action::SendMail.new(testAccount.name, outMessage).run
    end
  end,
  #Wait a bit for system to finish
  WaitQueue.new,

  v(cb("Block",600)do
    mboxid = ZMProv.new('gmi',testAccount.name).run[1].match(/mailboxId: (\d+)/)[1]
    result = RunCommand.new('/bin/ls','root',"/opt/zimbra/store/0/#{mboxid}").run[1]
    if result
        ZMProv.new('da',testAccount.name).run
        data = RunCommand.new('/bin/ls','root',"/opt/zimbra/store/0/#{mboxid}").run

        [data[0],data[1]]
    end
  end)do |mcaller,data|
     mcaller.pass = data[1].include?("No such file or directory")
  end,



]
#
# Tear Down
#
current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end