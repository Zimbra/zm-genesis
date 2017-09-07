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
# Test zmmsgtrace basic functions
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmmsgtrace"
require "action/zmbackup"
require "action/waitqueue"
require "action/date"
require "action/sendmail"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmsgtrace"
testAccount1 =
testAccount2 =
hostname = Model::TARGETHOST
from_hostname = "localhost.localdomain"
time = []

time1 = Action::Date.new('+%Y%m%d%H%M%S')
time2 = Action::Date.new('+%Y%m%d%H%M%S')
time3 = Action::Date.new('+%Y%m%d%H%M%S')

str_time1 =''
str_time2 =''
str_time3 =''

nNow = Time.now.to_i.to_s
nMount = File.join(Command::ZIMBRAPATH, 'zmmsgtrace'+nNow)
numberOfUser = 2
nameString = 'zmmsgtrace'+Time.now.to_i.to_s
testAccount1 = nameString +"1@#{Model::TARGETHOST}"
testAccount2 = nameString +"2@#{Model::TARGETHOST}"

#Message-Id: <20081124040703.883A710197F@rajgad.sahyadri.com>
msg_id = RunCommand.new('/bin/grep','root','-ir', 'Message-ID',Command::ZIMBRAPATH+"/store/0/*").run[1].match(/Message-Id: <(.*)>/)[1]


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

  CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),

  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
      address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
      outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
      1.upto(3) do
        Action::SendMail.new(address.name, outMessage).run
      end
    end
  end,

  #Wait a bit for system to finish
  WaitQueue.new,

  #time1,
  cb("time1",600)do
    str_time1 = time1.run[1].match(/.*(\d{14}).*/)[1]
  end,

  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
      address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
      outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
      1.upto(3) do
        Action::SendMail.new(address.name, outMessage).run
      end
    end
  end,

  #Wait a bit for system to finish
  WaitQueue.new,

  #time2,
  cb("time1",600)do
    str_time2 = time2.run[1].match(/.*(\d{14}).*/)[1]
  end,


  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
      address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
      outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
      1.upto(3) do
        Action::SendMail.new(address.name, outMessage).run
      end
    end
  end,

  #Wait a bit for system to finish
  WaitQueue.new,

  #time3,
  cb("time1",600)do
    str_time3 = time3.run[1].match(/.*(\d{14}).*/)[1]
  end,

  cb("Wait 120 seconds", 300) do  Kernel.sleep(120) end,

  v(ZMMsgtrace.new('-h')) do |mcaller, data|
        mcaller.pass = (data[0] == 1) && data[1].include?('usage')
  end,

  v(ZMMsgtrace.new('-s',"test.org" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0)
  end,


# It takes some time before msgs are listed in zmmsgtrace so try until msg are listed.
   v(cb("loop",1200) do
    data = [0,'']
    while !data[1].include?("Message ID")
      data = ZMMsgtrace.new('-s',"#{nNow}@testdomain.org" ).run
      Kernel.sleep(120)
    end

    [data[0],data[1]]
  end) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-r',testAccount1 )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-r',testAccount2 )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-r',testAccount1, '-s',"#{nNow}@testdomain.org" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,


  v(ZMMsgtrace.new('-r',"admin@#{Model::TARGETHOST}" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?('messages found')
  end,

  v(ZMMsgtrace.new('-s',"admin@#{Model::TARGETHOST}" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?('messages found')
  end,

  v(ZMMsgtrace.new('-r',"someone@somewhere.com" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?('0 messages found')
  end,

  v(ZMMsgtrace.new('-s',"someone@somewhere.com" )) do |mcaller, data|
        mcaller.pass = (data[0] == 0) && data[1].include?('0 messages found')
  end,
  v(ZMMsgtrace.new('-i',msg_id)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-s',"#{nNow}@testdomain.org")) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-s',"#{nNow}@testdomain.org",'-r',testAccount1)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-s',"#{nNow}@testdomain.org",'-r',testAccount1,'-F',from_hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(cb("test",600)do
      data =  ZMMsgtrace.new('-s',"#{nNow}@testdomain.org",'-r',testAccount1,'-F',from_hostname,'-D',hostname,'-t',"#{str_time1},#{str_time2}").run
    end )do |mcaller, data|
      mcaller.pass = (data[0] == 0) && data[1].include?("Message ID") && data[1].include?("messages found")
  end,

  v(ZMMsgtrace.new('-r',testAccount1)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-r',testAccount1,'-F',from_hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-r',testAccount1,'-F',from_hostname,'-D',hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(cb("test",600)do
      data =  ZMMsgtrace.new('-r',testAccount1,'-F',from_hostname,'-D',hostname,'-t',"#{str_time1},#{str_time2}").run
    end )do |mcaller, data|
      mcaller.pass = (data[0] == 0) && data[1].include?("Message ID") && data[1].include?("messages found")
  end,

  v(ZMMsgtrace.new('-F',from_hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(ZMMsgtrace.new('-F',from_hostname,'-D',hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,


  v(cb("test",600)do
      data =  ZMMsgtrace.new('-F',from_hostname,'-D',hostname,'-t',"#{str_time1},#{str_time2}").run
    end )do |mcaller, data|
      mcaller.pass = (data[0] == 0)&& data[1].include?("Message ID") && data[1].include?("messages found")
  end,


  v(ZMMsgtrace.new('-D',hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
  end,

  v(cb("test",600)do
      data =  ZMMsgtrace.new('-D',hostname,'-t',"#{str_time1},#{str_time2}").run
    end )do |mcaller, data|
      mcaller.pass = (data[0] == 0)&& data[1].include?("Message ID") && data[1].include?("messages found")
  end,


  v(cb("test",600)do
      data = ZMMsgtrace.new('-t',"#{str_time1},#{str_time2}").run
    end )do |mcaller, data|
      mcaller.pass = (data[0] == 0)&& data[1].include?("Message ID") && data[1].include?("messages found")
  end,


  v(ZMMsgtrace.new('-F',hostname)) do | mcaller, data |
    mcaller.pass = (data[0] == 0) && data[1].include?("Message ID")
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
  Engine::Simple.new(Model::TestCase.instance,true).run
end