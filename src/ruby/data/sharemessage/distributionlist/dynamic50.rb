#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
#  
# Dynamic distribution lists
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
current.description = "Dynamic distribution list test"

distAccount = Model::TARGETHOST.cUser('dynamicdist50'+Time.now.to_i.to_s, 
  Model::DEFAULTPASSWORD)
nameString = 'dl50'
numberOfUser = 50

include Action

message = <<EOF.gsub(/\n/, "\r\n").gsub(/RREPLACEME/, distAccount.name).gsub(/SUBJECT/, nameString)
Subject: SUBJECT
From: genesis@zimbra.com
To: RREPLACEME

This message is for MARKINDEX
This is for dynamic distribution list test
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
  ZMProv.new("cddl", distAccount.name),
  AddListMembers.new(distAccount.name, nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
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
  DeleteAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
  ZMProv.new('ddl', distAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
