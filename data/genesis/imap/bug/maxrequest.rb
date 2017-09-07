#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# Bug #45891, 73266, 68578, 79003
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
require "model"
require "action/zmprov"
require "action/proxy"
require "action/zmamavisd"
require "action/waitqueue"
require "action/sendmail"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Max Size"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
message = IO.readlines(File.join(Model::DATAPATH, 'imap', 'email_to_fetch.txt')).join

include Action 
#
# Setup
#
current.setup = []

#
# Execution
#
current.action = [  
  CreateAccount.new(testAccount.name,testAccount.password),
  #ZMProv.new('aal', testAccount.name, 'zimbra.imap', 'trace'),
  
  # login limit
  
  ZMProv.new('ms', Model::TARGETHOST.to_str, 'zimbraImapMaxRequestSize', 25),
  # next line is per bug #73266 - Nginx will forward login as literal
  ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', 5), 
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
  
  v(cb("login limit", 120) do
    response = nil 
    mimap2 = nil
    begin
      mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
      timeout(11) do
        mimap2.method('send_command').call("LOGIN #{testAccount.name} #{testAccount.password}") { |data| response = data }           
      end
    rescue => e
    end
    response
  end) do |mcaller, data|
    mcaller.pass = (data.name == "BAD" && (data.data.text.include?('size') || data.data.text.include?('length'))) ||
                   data.name == "BYE"
  end,
  
  # post login limit
  
  # such big limit is to work around Nginx sending ID request before login
  ZMProv.new('ms', Model::TARGETHOST.to_str, 'zimbraImapMaxRequestSize', 150), 
  ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', 10240000),
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
  
  v(cb("login limit", 120) do
    response = nil 
    mimap = nil
    begin
      mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
      mimap.login(testAccount.name,testAccount.password)
      mimap.select("INBOX")
      timeout(11) do
        mimap.method('send_command').call("SEARCH SUBJECT #{rand(36**140).to_s(36)}") { |data| response = data }           
      end
    rescue => e
    end  
    response
  end) do |mcaller, data|
    mcaller.pass = data.name == "BAD" && (data.data.text.include?('size') || data.data.text.include?('length'))
  end,
  
  # bug 79003
  # zimbraMtaMaxMessageSize set to 0
  ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', 0),
  v(ZMMailboxdctl.new('restart')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  ZMMailboxdctl.waitForMailboxd(),
  SendMail.new(testAccount.name, message.gsub('REPLACEME', 'bug79003')),
  WaitQueue.new(),
  v(cb("Message should be delievered", 120) do
    mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
    mimap.login(testAccount.name,testAccount.password)
    mimap.select("INBOX")
    mimap.uid_search("body bug79003")
  end) do |mcaller, data|
    mcaller.pass = data.is_a?(Array) && !data.empty?
  end,
  
  # reverting to defaults
  ZMProv.new('ms', Model::TARGETHOST.to_str, 'zimbraImapMaxRequestSize', 10240), #set it back to default
  ZMProv.new('mcf', 'zimbraMtaMaxMessageSize', 10240000),
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
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

