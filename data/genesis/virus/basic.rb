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
# Basic spam message test
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"

require "action/zmprov"
require "action/sendmail"
require "action/waitqueue"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "#{mypath}/install/configparser"
require "#{mypath}/install/errorscanner"
require 'action/zmamavisd'
require "action/decorator"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Virus basic test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
mimap = d

include Action

message = <<EOF.gsub(/\n/, "\r\n").gsub(/DEST/, testAccount.name)
From: user@example.com
To: DEST
Subject: test av
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="=-=-="

--=-=-=


testing av


--=-=-=
Content-Disposition: attachment; filename=eicar.com

X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*

--=-=-=--

EOF

(mCfg = ConfigParser.new).run
startTime = nil

imap_host = Model::Servers.getServersRunning("proxy").first ||
            Model::Servers.getServersRunning("mailbox").first

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
  CreateAccount.new(testAccount.name,testAccount.password),
  ZMAmavisd.new('restart'),
  v(cb("send eicar message") do
    startTime = DateTime.now
    Action::SendMail.new(testAccount.name,message).run
  end) do  |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  WaitQueue.new,
  v(cb("Fetch", 180) do
      mimap.object = Net::IMAP.new(imap_host, *Model::TARGETHOST.imap)
      mimap.login(testAccount.name, testAccount.password)
      mimap.select("INBOX")
      sleep(10)
      mimap.fetch('1:1', 'RFC822.HEADER')
    end) do  |mcaller, data|
      begin
        mcaller.pass = data[0].attr.values.join.include?('VIRUS')
      rescue
        mcaller.pass = false
      end
  end,
  mCfg.getServersRunning('mta').map do |x|
    v(cb("/var/log/zimbra.log errors detection test") do
      mResult = Action::RunCommand.new('tail', 'root', '-100', log = '/var/log/zimbra.log', Model::Host.new(x)).run
      next mResult << log if mResult[0] != 0
      #retain only errors after startTime (i.e upgrade only errors on upgrades)
      mResult[1] = mResult[1].split(/\n/).select  do |w|
                     DateTime.parse(w[/^([^:]+\d+(:\d+){2})/, 1] + startTime.zone + " " + startTime.year().to_s) >= startTime rescue true
                   end
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = mResult[1].select do |w|
                     w =~ sel
                   end.select do |w|
                     w !~ rej
                   end.collect {|w| w.strip}
      mResult << log
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
        mcaller.badones = {x + ' - ' + data.last + ' errors check' => {"IS"=>data[1].slice(0, 10).push('...').join("\n"), "SB"=>"No error"}}
      end
    end
  end,
  cb("Clean up") do
    mimap.logout
    mimap.disconnect
  end
]

#
# Tear Down
#
current.teardown = [
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
