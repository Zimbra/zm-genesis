#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2013 Vmware Zimbra
#
# zmmailbox message related basic testcases

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"

current = Model::TestCase.instance()
current.description = "Test zmmailbox message"

include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
msgDir1 = File.join(Model::DATAPATH, 'email01')
msgFile1 = File.join(msgDir1, 'msg01.txt')
invalidRFC822Dir = File.join(Model::DATAPATH, 'docs', 'rev1')
invalidRFC822File = File.join(invalidRFC822Dir, 'data.txt')
gzipDir = File.join('/opt/qa/genesis','data', 'TestMailRaw', 'compressed')
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

# Setup
#
current.setup = [
]

#
# Execution
#

current.action = [

  CreateAccount.new(testAccount.name, testAccount.password),  #test account

  v(RunCommand.new('zmmailbox', Command::ZIMBRAUSER, 'help', 'message')) do |mcaller,data|
    usage = [Regexp.escape('addMessage(am)               [opts] {dest-folder-path} {filename-or-dir} [{filename-or-dir} ...]'),
             Regexp.escape('-T/--tags <arg>              list of tag ids/names'),
             Regexp.escape('-F/--flags <arg>             flags'),
             Regexp.escape('-d/--date <arg>              received date (msecs since epoch)'),
             Regexp.escape('--noValidation               don\'t validate file content'),
             Regexp.escape('deleteMessage(dm)            {msg-ids}'),
             Regexp.escape('flagMessage(fm)              {msg-ids} [0|1*]'),
             Regexp.escape('getMessage(gm)               [opts] {msg-id}'),
             Regexp.escape('-v/--verbose                 verbose output'),
             Regexp.escape('markMessageRead(mmr)         {msg-ids} [0|1*]'),
             Regexp.escape('markMessageSpam(mms)         {msg} [0|1*] [{dest-folder-path}]'),
             Regexp.escape('moveMessage(mm)              {msg-ids} {dest-folder-path}'),
             Regexp.escape('tagMessage(tm)               {msg-ids} {tag-name} [0|1*]')
            ]
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select {|w| w !~ /^\s*$/}.size == usage.size &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,

  (('a'..'z').to_a + ('A'..'Z').to_a - %w[d F T]).map do |x|
    v(RunCommand.new('zmmailbox', Command::ZIMBRAUSER, '-z', '-d',
                     '-m', testAccount.name, 'am', '-' + x, '/Inbox', msgFile1)) do |mcaller, data|
      mcaller.pass = data[0] != 0 &&
                     ZMMail.outputOnly(data[1]).chomp == "ERROR: zclient.CLIENT_ERROR (unknown folder: -#{x})"
    end
  end,
  
  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', msgDir1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{msgFile1}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', invalidRFC822Dir)) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1] =~ /#{invalidRFC822Dir}\S+ does not contain a valid RFC 822 message/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox', msgDir1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{msgFile1}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox', invalidRFC822Dir)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{invalidRFC822File}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', msgFile1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{msgFile1}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', invalidRFC822File)) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1] =~ /#{invalidRFC822Dir}\S+ does not contain a valid RFC 822 message/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox', msgFile1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{msgFile1}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox', invalidRFC822File)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{invalidRFC822File}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', mInvalidGzipFile = File.join(gzipDir, 'invalid_email.gz'))) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1] =~ /#{File.join(gzipDir, 'invalid_email.gz')} does not contain a valid RFC 822 message/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '/Inbox', validGzipFile = File.join(gzipDir, 'valid_email.gz'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{File.join(gzipDir, 'valid_email.gz')}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox', mInvalidGzipFile)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{mInvalidGzipFile}\))$/
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'am', '--noValidation', '/Inbox',  validGzipFile)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\d+\s(\(#{ validGzipFile}\))$/
  end,


  #TODO : add tests for addMessage options -T -F -d
  #TODO : deleteMessage(dm) tests
  #TODO : flagMessage(fm) tests
  #TODO : getMessage(gm) tests
  #TODO : markMessageRead(mmr) tests
  #TODO : markMessageSpam(mms) tests
  #TODO : moveMessage(mm) tests
  #TODO : tagMessage(tm) tests

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
