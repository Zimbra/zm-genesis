#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 Vmware Zimbra
#
# Functional tests on zmdkimkeyutil with custom selector
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block" 
 
require "action/zmprov" 
require "action/sendmail" 
require "action/waitqueue"
require "action/zmdkimkeyutil"
require "action/decorator"
require "action/verify" 
require "action/zmprov"
require "action/decorator"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

include Action
#Net::IMAP.debug=true

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Functional test zmdkimkeyutil with selector"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
testAccount2 = Model::TARGETHOST.cUser(name+"123", Model::DEFAULTPASSWORD)

mimap = d

message = <<EOF.gsub(/\n/, "\r\n")
Date: Fri, 23 Feb 2007 16:57:04 -0800
User-Agent: Thunderbird 1.5.0.9 (Windows/20061207)
Subject: testing DKIM 
Some messages for DKIM signature testing.

EOF

mselector = "slt_" + Time.now.to_i.to_s

run_on_mta = Model::Host.new(Model::Servers.getServersRunning("mta").first)
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
  
  CreateAccount.new(testAccount.name,testAccount.password),
  CreateAccount.new(testAccount2.name,testAccount2.password),

  # add new DKIM signature
  v(ZMDkimkeyutil.new("-a", "-s", mselector, "-d", Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Data added to LDAP for domain #{Model::TARGETHOST} with selector #{mselector}") &&
                     data[1].match("Public signature to enter into DNS:") &&
                     data[1].match(/^#{Regexp.quote(mselector)}.*_domainkey.*IN.*TXT.*v=DKIM1; k=rsa;.*p=.*;.*DKIM key #{Regexp.quote(mselector)} for #{Regexp.quote(Model::TARGETHOST)}/m)
  end,
  
  # send message from domain with new signature
  # from user 2 to user 1
  Action::SendMail.new(testAccount.name,message, testAccount2.name, run_on_mta),
  Action::WaitQueue.new(600, run_on_mta),
  
  # check the message is signed
  v(cb("Check message headers") do
    result = []
    mimap.object = Net::IMAP.new(imap_host, *Model::TARGETHOST.imap)
    mimap.login(testAccount.name, testAccount.password)
    mimap.select("INBOX")
    result[0] = mimap.fetch(1, "BODY[HEADER.FIELDS (DKIM-SIGNATURE)]")[0][:attr]
    result[1] = mimap.fetch(1, "BODY[HEADER.FIELDS (AUTHENTICATION-RESULTS)]")[0][:attr]
    result[2] = mimap.fetch(1, "BODY[HEADER.FIELDS (DKIM-FILTER)]")[0][:attr]
    result
  end) do |mcaller, data|
    mcaller.pass = !data[0]["BODY[HEADER.FIELDS (DKIM-SIGNATURE)]"].chomp.empty? &&
                   !data[1]["BODY[HEADER.FIELDS (AUTHENTICATION-RESULTS)]"].chomp.empty? &&
                   !data[2]["BODY[HEADER.FIELDS (DKIM-FILTER)]"].chomp.empty? &&
                   data[0]["BODY[HEADER.FIELDS (DKIM-SIGNATURE)]"].match(/s=#{Regexp.quote(mselector)};/)
  end,
  
  # get DKIM info for domain using selecto
  v(ZMDkimkeyutil.new("-q", "-s", mselector, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Domain:\n#{Model::TARGETHOST}") &&
                     data[1].match("DKIM Identity:\n#{Model::TARGETHOST}") &&
                     data[1].match(/DKIM Selector:\n#{Regexp.quote(mselector)}/) &&
                     data[1].match(/DKIM Private Key:\n-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----/m) &&
                     data[1].match(/DKIM Public signature:\n#{Regexp.quote(mselector)}\._domainkey.*IN.*TXT.*v=DKIM1; k=rsa;.*p=.*;.*DKIM key #{Regexp.quote(mselector)} for #{Regexp.quote(Model::TARGETHOST)}/m)
  end,
  
  # update DKIM signature
  v(ZMDkimkeyutil.new("-u", "-s", "slt_" + Time.now.to_i.to_s + "_alt", "-d", Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Data added to LDAP for domain #{Model::TARGETHOST} with selector") &&
                     data[1].match("Public signature to enter into DNS:") &&
                     data[1].match(/\._domainkey.*IN.*TXT.*v=DKIM1; k=rsa;.*p=/m) &&
                     data[1].match(/with selector (.*)\n/)[1] != mselector &&
                     data[1].match(/^(.*)\._domainkey/)[1] != mselector &&
                     data[1].match(/DKIM (.*) for/)[1] != mselector
      if mcaller.pass
        mselector = data[1].match(/with selector (.*)\n/)[1]
      end
  end,
  
  # get new DKIM info for domain using domain name
  v(ZMDkimkeyutil.new("-q", "-d", Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Domain:\n#{Model::TARGETHOST}") &&
                     data[1].match("DKIM Identity:\n#{Model::TARGETHOST}") &&
                     data[1].match(/DKIM Selector:\n#{Regexp.quote(mselector)}/) &&
                     data[1].match(/DKIM Private Key:\n-----BEGIN RSA PRIVATE KEY-----.*-----END RSA PRIVATE KEY-----/m) &&
                     data[1].match(/DKIM Public signature:\n#{Regexp.quote(mselector)}\._domainkey.*IN.*TXT.*v=DKIM1; k=rsa;.*p=.*;.*DKIM key #{Regexp.quote(mselector)} for #{Regexp.quote(Model::TARGETHOST)}/m)
  end,
  
  # remove DKIM signature
  v(ZMDkimkeyutil.new("-r", "-d", Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("DKIM Data deleted in LDAP for domain #{Model::TARGETHOST}") 
  end,
  
  # get no DKIM info for domain
  v(ZMDkimkeyutil.new("-q", "-d", Model::TARGETHOST.to_s, run_on_mta)) do |mcaller,data|
      mcaller.pass = data[0] = 0 &&
                     data[1].match("No DKIM Information for domain #{Model::TARGETHOST}")
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
  DeleteAccount.new(testAccount.name),
  DeleteAccount.new(testAccount2.name)
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
