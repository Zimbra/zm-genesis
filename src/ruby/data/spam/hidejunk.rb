#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Hide Junk folder test
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block" 
 
require "action/zmprov" 
require "action/sendmail" 
require "action/waitqueue"
require "action/decorator"
require "action/verify" 
require "action/zmcontrol"
require "action/zmprov"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

include Action
#Net::IMAP.debug=true
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Hide Junk folder test"

name = 'spam'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
testAccount2 = Model::TARGETHOST.cUser(name+"123", Model::DEFAULTPASSWORD)

mimap = d
mimap2 = d

message = IO.readlines(File.join(Model::DATAPATH, 'spam', 'hide.txt')).join
message.gsub!(/\n/, "\r\n").gsub!(/DEST/, testAccount.name)

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
  CreateAccount.new(testAccount2.name,testAccount2.password),
  
  # Disable spam filtering for an account
  v(ZMProv.new('ma', testAccount, 'zimbraFeatureAntispamEnabled', 'FALSE')) do |mcaller, data|
    isSet = ZMProv.new('ga', testAccount).run[1]
    mcaller.pass = (data[0] == 0) && isSet.include?('zimbraFeatureAntispamEnabled: FALSE')
  end,
  
  # Send middle score spam message
  Action::SendMail.new(testAccount.name,message),    
  Action::WaitQueue.new,
  
  cb("login") do
    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mimap.login(testAccount.name, testAccount.password)
  end,
  
  # Perform imap operations to confirm Junk folder is hidden
    
  v(cb("List Junk") do
    mimap.list('', 'Junk')
  end) do |mcaller, data|
    mcaller.pass = (data.class == NilClass)
  end,
  
  #  
  v(cb("Spam message gets to Inbox") do
    mimap.select('INBOX')
    mimap.fetch((1..-1), 'RFC822.HEADER')
  end) do  |mcaller, data|
    begin
      mcaller.pass = data[0].attr.values.join.include?('X-Spam-Flag: YES')     
    rescue
      mcaller.pass = false
    end 
  end,
  
  ['select', 'create', 'examine'].map do |x|
    v(cb("No response on #{x}") do
      mimap.method('send_command').call("#{x} Junk")
    end) do |mcaller, data|
      mcaller.pass = (data.class ==  Net::IMAP::NoResponseError)
    end
  end,
  
  v(cb("Copy message to Junk") do
    mimap.select("INBOX")
    mimap.copy((1..-1), 'Junk')
  end) do |mcaller, data|
      mcaller.pass = (data.class ==  Net::IMAP::NoResponseError)
  end,
  
  v(cb("Append message to Junk") do
    mimap.append('Junk', message, [:Seen], Time.now)
  end) do |mcaller, data|
      mcaller.pass = (data.class ==  Net::IMAP::NoResponseError)
  end,
  
  v(cb("List should not contain Junk") do
    mimap.list('', '*')
  end) do |mcaller, data|
    mcaller.pass = ! data.any? { |s| s.include?('Junk') }
  end,
  
  # Disable spam filtering for all the default COS and check another account
  ZMProv.new('mc', 'default', 'zimbraFeatureAntispamEnabled', 'FALSE'),
  cb("login") do
    mimap2.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mimap2.login(testAccount2.name, testAccount2.password)
  end,
  
  v(cb("List should not contain Junk 2") do
    mimap2.list('', '*')
  end) do |mcaller, data|
    mcaller.pass = ! data.any? { |s| s.include?('Junk') }
  end,
  
  # revert changes
  cb("logout") do
    mimap.logout
    mimap2.logout
    mimap.disconnect
    mimap2.disconnect
  end
  
]

#
# Tear Down
#
current.teardown = [
  DeleteAccount.new(testAccount.name),
  DeleteAccount.new(testAccount2.name),

  ZMProv.new('mc', 'default', 'zimbraFeatureAntispamEnabled', 'TRUE')
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
