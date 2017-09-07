#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare.
#
# Basic whitelist message test
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "model"
require "action/block" 
 
require "action/zmprov" 
require "action/sendmail" 
require "action/waitqueue" 
require "action/verify" 
require "action/zmcontrol"
require "action/zmprov"
require 'action/zmamavisd'
require "action/zmlmtpinject"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Whitelist filter test"

name = 'spam'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action


whitelistHeader = 'X-Whitelist-Flag'
whitelistHeaderValue = 'YES'
rawMessage = IO.readlines(File.join(Model::DATAPATH, 'spam', 'spam1.txt'))
mFile = File.join(Command::ZIMBRAPATH, 'data', 'tmp', "#{name}.txt")


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
  cb("check settings") do
    needRestart = false
    if ZMProv.new('gcf', 'zimbraSpamWhitelistHeader').run[1] !~ /#{whitelistHeader}/
      ZMProv.new('mcf', 'zimbraSpamWhitelistHeader', whitelistHeader).run
    end
    if ZMProv.new('gcf', 'zimbraSpamWhitelistHeaderValue').run[1] !~ /#{whitelistHeaderValue}/
      ZMProv.new('mcf', 'zimbraSpamWhitelistHeaderValue', whitelistHeaderValue).run
    end
    ZMMailboxdctl.new('restart').run if needRestart
  end,
  cb("Create message file") do
    message = rawMessage.collect {|w| if w !~ /X-Spam-Flag: YES/ then w else ["#{whitelistHeader}: #{whitelistHeaderValue}\n",w] end}.flatten
    message = message.collect {|w| w.gsub(/To: \S+/, "To: #{testAccount.name}")}
    File.open(mFile, "w") do |file|
      file.puts message.join('')
    end
  end,
  ZMLmtpinject.new('-r', testAccount.name, '-s', 'genesis@zimbratest.com', mFile),
  Action::WaitQueue.new,    
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('select'), 'INBOX'),
  v(cb("Fetch INBOX Mail") do
    File.delete(mFile)
    m.fetch((1..-1), 'RFC822.HEADER')
  end) do  |mcaller, data|
    begin
      mcaller.pass = data[0].attr.values.join.include?("#{whitelistHeader}")
      mcaller.pass = true
    rescue
      mcaller.pass = false
    end
  end,
  #TODO: whitelist not the first line
  #      message is passed to filters
=begin
  Action::SendMail.new(testAccount.name,message2),    
  Action::WaitQueue.new,    
    v(cb("Fetch Normal Mail") do  
      m.fetch((1..-1), 'RFC822.HEADER')
    end) do  |mcaller, data|
      begin
        mcaller.pass = data[0].attr.values.join.include?('X-Spam-Score')     
      rescue
        mcaller.pass = false
      end 
  end,
  Action::WaitQueue.new
=end
]

#
# Tear Down
#
current.teardown = [
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
