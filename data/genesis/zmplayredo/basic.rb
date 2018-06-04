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
# Test zmplayredo basic functions
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
require "action/date"
require "action/waitqueue"
require "action/zmplayredo"
require "action/zmamavisd"
require "action/sendmail"
require "model"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmplayredo"

nNow = Time.now.to_i.to_s
nMount = File.join(Command::ZIMBRAPATH, 'playredo'+nNow)
numberOfUser = 3
nameString = 'playredo'+Time.now.to_i.to_s

time0 = Action::Date.new('+%Y%m%d%H%M%S')
time1 = Action::Date.new('+%Y%m%d%H%M%S')
time2 = Action::Date.new('+%Y%m%d%H%M%S')
mboxid = ''

testSeq = Array.new

RunCommandOnMailbox.new('/bin/ls', 'root', "/opt/zimbra/redolog/archive/*.log").run[1].split(/\n/).grep(/.*-seq.*log/).each do |x|
  testSeq.push   x.match(/.*-seq(\d+)\.log/)[1]
end


def noError
  proc do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for") &&
                   data[1].include?("redolog files to play back") &&
                   data[1].include?("Processing log file")
  end
end


message = <<EOF.gsub(/\n/, "\r\n")
Subject: playredo
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

  RunCommandOnMailbox.new('/bin/mkdir','root',nMount),
  RunCommandOnMailbox.new('/bin/chown','root','zimbra:zimbra', nMount),
  RunCommandOnMailbox.new('/bin/chgrp','root','zimbra', nMount),

  #Create Accounts
  CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
  cb("Block",600)do
    mboxid = ZMProv.new('gmi',"#{nameString}1@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/)[1]
  end,

  #Send emails
  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
        address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
        outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
        1.upto(2) do
          Action::SendMail.new(address.name, outMessage).run
        end
    end
  end,
  #Wait a bit for system to finish
  WaitQueue.new,

  time1,

  cb("Send Emails", 600) do
    1.upto(numberOfUser) do |x|
        address = Model::TARGETHOST.cUser("#{nameString}#{x}", Model::DEFAULTPASSWORD)
        outMessage = message.gsub(/REPLACEME/,address.name).gsub(/MARKINDEX/, address.name)
        1.upto(2) do
          Action::SendMail.new(address.name, outMessage).run
        end
    end
  end,
  WaitQueue.new,

  time2,

  RunCommandOnMailbox.new('/bin/cp','zimbra','-R', File.join(Command::ZIMBRAPATH ,'redolog'), nMount),

  if(testSeq[1])
    v(ZMPlayredo.new('--fromSeq', testSeq[1] )) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                     data[1].include?("Replaying operations for all mailboxes") &&
                     data[1].include?("Using 50 redo player threads") &&
                     data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                     data[1].include?("Processing log file")
    end
  end,

  v(cb("Check to see if there is any .bak file under store bug 40841") do
      RunCommandOnMailbox.new('find', 'zimbra', File.join(Command::ZIMBRAPATH, 'store'), '-name "*.bak"').run
    end) do |mcaller, data|
    mcaller.pass = !data[1].include?('.bak')
  end,

  v(ZMPlayredo.new('--fromTime', time1.ctimestamp)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") && 
                   data[1].include?("Replaying operations for all mailboxes") && 
                   data[1].include?("Using 50 redo player threads") && 
                   data[1].include?("Using 100 as queue capacity for each redo player thread") && 
                   if(testSeq[1])
                     data[1].include?("Processing log file")
                   else
                     data[1].include?("0 redolog files to play back")
                   end
  end,

  v(ZMPlayredo.new('-h')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("usage: zmplayredo <options>")
  end,

  v(ZMPlayredo.new('--help')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("usage: zmplayredo <options>")
  end,

  v(ZMPlayredo.new('--logfiles', "#{nMount}/redolog/*.log")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for all mailboxes") &&
                   data[1].include?("Using 50 redo player threads") &&
                   data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  v(cb("block",600)do
      data = ZMPlayredo.new('--mailboxId',mboxid).run
    end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.")&&
                   data[1].include?("Replaying operations for") &&
                   data[1].include?("Using 50 redo player threads") &&
                   data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  v(ZMPlayredo.new('--queueCapacity','70')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for all mailboxes") &&
                   data[1].include?("Using 50 redo player threads") &&
                   data[1].include?("Using 70 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  v(ZMPlayredo.new('--stopOnError')) do |mcaller, data|
    if(testSeq[1])
      mcaller.pass = data[0] == 1 && data[1].include?("Redo playback stopped due to an earlier error")
    else
      mcaller.pass = data[0] == 0 && data[1].include?("1 redolog files to play back")
    end
  end,

  v(ZMPlayredo.new('--threads', '25')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for all mailboxes") &&
                   data[1].include?("Using 25 redo player threads") &&
                   data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  if(testSeq[-1])
    v(ZMPlayredo.new('--toSeq',testSeq[-1])) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                     data[1].include?("Replaying operations for all mailboxes") &&
                     data[1].include?("Using 50 redo player threads") &&
                     data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                     data[1].include?(" redolog files to play back") &&
                     data[1].include?("Processing log file")
    end
  end,

  if(testSeq.first)
    v(ZMPlayredo.new('--toSeq',testSeq.first)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                     data[1].include?("Replaying operations for all mailboxes") &&
                     data[1].include?("Using 50 redo player threads") &&
                     data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                     data[1].include?(" redolog files to play back") &&
                     data[1].include?("Processing log file")
    end
  end,


  v(ZMPlayredo.new('--toTime', time2.ctimestamp)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for all mailboxes") &&
                   data[1].include?("Using 50 redo player threads") &&
                   data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  v(ZMPlayredo.new('--logfiles',"#{nMount}/redolog/*.log")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("mailboxd is not running.") &&
                   data[1].include?("Replaying operations for all mailboxes") &&
                   data[1].include?("Using 50 redo player threads") &&
                   data[1].include?("Using 100 as queue capacity for each redo player thread") &&
                   data[1].include?(" redolog files to play back") &&
                   data[1].include?("Processing log file")
  end,

  v(ZMPlayredo.new('--logfiles',"#{nMount}/redolog/archive/*.log")) do |mcaller, data|
    mcaller.pass = data[1].include?("mailboxd is not running.") &&
    data[1].include?("Replaying operations for all mailboxes") &&
      data[1].include?("Using 50 redo player threads") &&
      data[1].include?("Using 100 as queue capacity for each redo player thread") &&
      if(testSeq[-1])
        data[1].include?(" redolog files to play back") &&
        data[1].include?("Processing log file") &&
        data[0] == 0
      else
        data[1].include?("No such file") or data[2].include?('No such file:') &&
        data[0] == 1
      end
  end,

  v(ZMPlayredo.new('--logfiles',"#{nMount}/redolog/bad/*.log")) do |mcaller, data|
    mcaller.pass = data[0] == 1 && (data[1].include?('No such file:') or data[2].include?('No such file:'))
  end,

  v(ZMPlayredo.new('-bad')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && (data[1].include?('Unrecognized option: -bad') or data[2].include?('Unrecognized option: -bad'))
  end,

  v(ZMPlayredo.new('--toTime', '123456789')) do |mcaller, data|
    mcaller.pass =  data[0] == 1 && (data[1].include?('Invalid timestamp') or data[2].include?('Invalid timestamp'))
  end,

  v(ZMPlayredo.new('--fromTime', '123456789')) do |mcaller, data|
    mcaller.pass =  data[0] == 1 && (data[1].include?('Invalid timestamp') or data[2].include?('Invalid timestamp'))
  end,

  v(ZMPlayredo.new('--toSeq', '123456789')) do |mcaller, data|
    mcaller.pass =  data[0] == 0
  end,

  v(ZMPlayredo.new('--fromSeq', '123456789')) do |mcaller, data|
    mcaller.pass =  data[0] == 0
  end,

  v(ZMMailboxdctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,


]
#
# Tear Down
#

current.teardown = [
                    cb("Force sleep", 120) do
                      sleep(60)
                    end

                   ]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
