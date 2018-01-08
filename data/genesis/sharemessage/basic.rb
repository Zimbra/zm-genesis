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
# Basic share message test
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block" 
require "action/zmhsm"
require "action/zmprov"
require "action/zmvolume"
require "action/runcommand"
require "action/waitqueue"
require "action/verify" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Share message test"

adminAccount = Model::TARGETHOST.cUser('admin',Model::DEFAULTPASSWORD)
nameString = 'sharemsgbasic'
numberOfUser = 2

include Action

message = <<EOF.gsub(/\n/, "\r\n").gsub(/ORIG/, adminAccount.name)
Subject: hsmtest
From: ORIG
To: RREPLACEME
To: REPLACMETWO

This message is for MARKINDEX
This is for basic share message test
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
  #Create accounts
  CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
  ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "sharemessage"+Time.now.to_i.to_s),  testPath, 'primaryMessage'),
  #Send emails
  cb("Send Emails") do
    1.upto(numberOfUser/2) do |x|
      addressOne = Model::TARGETHOST.cUser("#{nameString}#{x*2-1}", Model::DEFAULTPASSWORD)
      addressTwo = Model::TARGETHOST.cUser("#{nameString}#{x*2}", Model::DEFAULTPASSWORD)
      outMessage = message.gsub(/RREPLACEME/,addressOne.name).gsub(/MARKINDEX/, "#{addressOne.name} #{addressTwo.name}").
        gsub(/REPLACMETWO/, addressTwo.name)
      SendMail.new([addressOne.name, addressTwo.name], outMessage).run
    end
  end,
  Action::WaitQueue.new,
  #Verify that all message are still accessible
  (1..numberOfUser).to_a.map do |currentuser|
    ZMHsmHelper.genDataValidation(Model::TARGETHOST, Model::TARGETHOST.cUser("#{nameString}#{currentuser}", Model::DEFAULTPASSWORD))
  end,
#  v(RunCommand.new("/bin/ls", "-l",'-R', mfilePath)) do |mcaller, data|
  v(RunCommandOnMailbox.new('/bin/ls', 'root', '-l', '-R',
    File.join(Command::ZIMBRAPATH, testPath))) do |mcaller, data|
    #Two messages and both of them hard linked
    result = data[1].split("\n").select { |y| y =~ /\.msg/}
    mcaller.pass = result.size == 2 
  end,
  ZMVolumeHelper.genReset
]

#
# Tear Down
#
current.teardown = [
  DeleteAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end