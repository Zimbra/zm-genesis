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
# Test zmblobchk star, stop, reload
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
require "action/zmblobchk"
require "action/waitqueue"
require "action/sendmail.rb"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmblobchk"
name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount1 = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
mboxId = ""
oldBlobPath = ""
newBlobPath = ""
blobEmail = <<EOF.gsub(/\n/, "\r\n").gsub(/REPLACETO/, testAccount1.name).gsub(/REPLACEFROM/, 'foo@coo.com')
Subject: hello plain
From: REPLACEFROM
To: REPLACETO

hello world this is a test email.
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

  v(ZMBlobchk.new('-h')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('usage: zmblobchk')
  end,

  v(ZMBlobchk.new('--help')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('usage: zmblobchk')
  end,

  v(ZMBlobchk.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMBlobchk.new('--skip-size-check start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

# v(ZMBlobchk.new('--skip-fs start')) do |mcaller, data|
#   mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
# end,

  v(ZMBlobchk.new('-l')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('Unrecognized option: -l')
  end,

  v(ZMBlobchk.new('--load')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('Unrecognized option: --load')
  end,

  v(ZMBlobchk.new('-l','bad')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('Unrecognized option: -l')
  end,

  v(ZMBlobchk.new('--load','bad')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('Unrecognized option: --load')
  end,

  v(ZMBlobchk.new('-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i, 'start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
# commenting out as zmblobchk has been changed a lot. Bug #41836
## bad account name
#  v(ZMBlobchk.new('-m',"wrongaccount@#{Model::TARGETHOST}")) do |mcaller, data|
#    mcaller.pass = (data[0] == 1) && data[1].include?('not found!')
#  end,
# bad mboxid
  v(ZMBlobchk.new('-m','123456789', 'start')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('no such mailbox: 123456789')
  end,


  v(ZMBlobchk.new('-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i,'start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

# commenting out as zmblobchk has been changed a lot. Bug #41836
#  v(ZMBlobchk.new('-m',"admin@#{Model::TARGETHOST}",'-z')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,

  v(ZMBlobchk.new('-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i,'start')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

# commenting out as zmblobchk has been changed a lot. Bug #41836
#  v(ZMBlobchk.new('--skip-size-check','-m',"admin@#{Model::TARGETHOST}")) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,

#  v(ZMBlobchk.new('--skip-size-check','-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i)) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,

#  v(ZMBlobchk.new('--skip-size-check','-m',"admin@#{Model::TARGETHOST}",'-z')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,

  v(ZMBlobchk.new('--skip-size-check','-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i,'start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Checking mailbox')
  end,

# Commenting out as "-p" option is no more
#  v(ZMBlobchk.new('--skip-size-check','-p',(RunCommand.new('/opt/zimbra/bin/zmlocalconfig', 'zimbra', '-s', '|', 'grep', 'zimbra_mysql_password').run[1].match(/zimbra_mysql_password = (.+)/))[1]),'start') do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,
#
#  v(ZMBlobchk.new('--skip-size-check','-m',(ZMProv.new('gmi',"admin@#{Model::TARGETHOST}").run[1].match(/mailboxId: (\d+)/))[1].to_i,'-p',(RunCommand.new('/opt/zimbra/bin/zmlocalconfig', 'zimbra', '-s', '|', 'grep', 'zimbra_mysql_password').run[1].match(/zimbra_mysql_password = (.+)/)[1]),'start')) do |mcaller, data|
#    mcaller.pass = (data[0] == 0) && data[1].include?('Retrieving items from mboxgroup')
#  end,

  CreateAccount.new(testAccount1.name, testAccount1.password),
  SendMail.new(testAccount1.name, blobEmail),

  WaitQueue.new,

  v(cb("Find mailboxId & Rename the blob")do
    mboxId = ZMProv.new('gmi', testAccount1.name).run[1].match(/mailboxId: (\d+)/)[1]
    oldBlobPath = ZMBlobchk.new('-m', mboxId, '--output-used-blobs start').run[1].match(/.*volume\s\d+,\s(.*)./)[1]
    dirName = File.dirname(oldBlobPath)
    blobName = File.basename(oldBlobPath,".msg").split("-")
    newBlobPath = "#{dirName}/#{blobName.first}-#{blobName.last.next}.msg"
    RunCommand.new('mv', 'root', oldBlobPath, newBlobPath).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(cb("Check that blob file renamed to the original name") do
    ZMBlobchk.new('-m', mboxId, '--incorrect-revision-rename-file start').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].include?("#{newBlobPath}: file has incorrect revision") &&
                   data[1].include?("Renaming #{newBlobPath} to #{oldBlobPath}")
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