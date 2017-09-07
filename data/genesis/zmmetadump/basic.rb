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
# Test zmstatctl star, stop, reload
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmmetadump"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmetadump"
name = "zmmetadump"+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
mboxId= ''

message = <<EOF.gsub(/\n/, "\r\n")
Subject: restoreabort
From: genesis@test.org
To: REPLACEME

This message is for MARKINDEX
This is for restore abort test
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
  CreateAccount.new(testAccount.name,testAccount.password),

  v(ZMMetadump.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage: zmmetadump')
  end,

  v(ZMMetadump.new('-bad')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Unrecognized option')
  end,

  v(ZMMetadump.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage: zmmetadump')
  end,

  v(ZMMetadump.new('--help')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Usage: zmmetadump')
  end,

  cb("block",600)do
    mboxId = ZMProv.new('gmi',testAccount.name).run[1].match(/mailboxId: (\d+)/)[1]
  end,

  v(ZMMetadump.new('-m',testAccount.name,'-i','13')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('name: Emailed Contacts')
  end,

  v(
    cb("Test",600) do
       mboxId = ZMProv.new('gmi',testAccount.name).run[1].match(/mailboxId: (\d+)/)[1]
       data = ZMMetadump.new('-m',"#{mboxId}",'-i','13').run
       [data[0],data[1]]
    end
   )do |mcaller, data|
      mcaller.pass = (data[0] == 0) && data[1].include?('name: Emailed Contacts')
   end,

# Bug 32825
  v(ZMMetadump.new('-m','badid@mydomain.com','-i','13')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) #&& !data[1].include?('Exception in thread')
    if !mcaller.pass
      mcaller.message = "Bug: 32825"
    end
  end,

  v(ZMMetadump.new('-m','123456789','-i','13')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) #&& !data[1].include?('Exception in thread')

    if !mcaller.pass
      mcaller.message = "Bug: 32825"
    end
  end,

  v(ZMMetadump.new('-m',testAccount.name,'-i','123456789')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) #&& !data[1].include?('Exception in thread')

    if !mcaller.pass
      mcaller.message = "Bug: 32825"
    end
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