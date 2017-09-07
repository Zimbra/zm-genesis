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
#  
# Distribution list share message 50 users test
# This depends on  postconf | grep _destination_recipient_limit which is 50 at this moment
# Adjust this test case when that is changed
# 
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"  
require "action/zmprov" 
require "action/zmvolume"
require "action/runcommand"
require "action/waitqueue" 
require "action/verify" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Share distributionlist 50 test"

distAccount = Model::TARGETHOST.cUser('dist50'+Time.now.to_i.to_s, 
  Model::DEFAULTPASSWORD)
nameString = 'dl50'
numberOfUser = 50

include Action

message = <<EOF.gsub(/\n/, "\r\n").gsub(/RREPLACEME/, distAccount.name)
Subject: hsmtest
From: genesis@zimbratest.com
To: RREPLACEME

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
  ZMVolumeHelper.genCreateSet(mfilePath = File.join(Command::ZIMBRAPATH, testPath = "dl50"+Time.now.to_i.to_s),  testPath, 'primaryMessage'),
  #Create Distribution List
  ZMProv.new("cdl", distAccount.name),   
  cb("Add Disbribution List Member", 2400) do
    begin
      1.upto(numberOfUser) do |x|
        Action::ZMProv.new("adlm", distAccount.name, Model::TARGETHOST.cUser("#{nameString}#{x}")).run     
      end
    rescue => e
      e
    end
  end,  
  #Send emails
  SendMail.new(distAccount.name, message), 
  Action::WaitQueue.new, 
  v(RunCommand.new('/bin/ls', 'root', '-l', '-R',
    File.join(Command::ZIMBRAPATH, testPath)), 2400) do |mcaller, data|
     #Fifty messages and both of them hard linked
      result = data[1].split("\n").select { |y| y =~ /\.msg/}
      mcaller.pass = (result.size == numberOfUser) && result.all? { |x| x =~ /#{numberOfUser} zimbra/ }
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
