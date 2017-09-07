#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Enh 24401 New folders are not subscribed via imap per default
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Autosubscription for new folders"

name1 = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s+'1'
name2 = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s+'2'
testAccount1 = Model::TARGETHOST.cUser(name1, Model::DEFAULTPASSWORD)
testAccount2 = Model::TARGETHOST.cUser(name2, Model::DEFAULTPASSWORD)

mimap1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
   
]

#
# Execution
#

current.action = [  

  CreateAccount.new(testAccount1.name,testAccount1.password),

  proxy(mimap1.method('login'),testAccount1.name,testAccount1.password), 
  ['FALSE', 'TRUE'].map do |x|
  [
    ZMProv.new('mcf', 'zimbraImapDisplayMailFoldersOnly', x),
    v(cb("Nothing should be subscribed by default") do
      result = []
      result[0] = mimap1.list("", "*")
      result[1] = mimap1.lsub("","*")
      result
    end ) do |mcaller, data|
      mcaller.pass = data[0].size == 8 - (x == 'TRUE' ? 2 : 0) && data[1] == nil
    end,
    proxy(mimap1.method("create"),"INBOX/test1"),
    v(cb("Newly created folder in not subscribed") do
      result = []
      result[0] = mimap1.list("", "*")
      result[1] = mimap1.lsub("","*")
      result
    end ) do |mcaller, data|
      mcaller.pass = data[0].size == 9 - (x == 'TRUE' ? 3 : 0) && data[1] == nil && data[0].inspect.include?("INBOX/test1")
    end
  ]
  end,
    
  # enable autosubscribe for 'default' COS
  v(ZMProv.new('mc default zimbraDefaultFolderFlags "*"')) do |mcaller, data|
      mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('gc', 'default', 'zimbraDefaultFolderFlags')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  # check new folder autosubscibe
  ['FALSE', 'TRUE'].map do |x|
  [
    ZMProv.new('mcf', 'zimbraImapDisplayMailFoldersOnly', x),
    v(cb("Nothing should be subscribed on old folders") do
      result = []
      result[0] = mimap1.list("", "*")
      result[1] = mimap1.lsub("","*")
      result
    end ) do |mcaller, data|
      mcaller.pass = data[0].size == 9 - (x == 'TRUE' ? 2 : 0) && (data[1].nil? || data[1].inspect.include?("INBOX/test2"))
    end,
    proxy(mimap1.method("create"),"INBOX/test2"),
    v(cb("Newly created folder in subscribed") do
      result = []
      result[0] = mimap1.list("", "*")
      result[1] = mimap1.lsub("","*")
      result
    end ) do |mcaller, data|
      mcaller.pass = data[0].size == 10 - (x == 'TRUE' ? 3 : 0) && data[1].size == 1 && data[1].inspect.include?("INBOX/test2")
    end
  ]
  end,
  
  # check newly created account
  CreateAccount.new(testAccount2.name,testAccount2.password),

  proxy(mimap2.method('login'),testAccount2.name,testAccount2.password), 
  v(cb("List and lsub should give the same default folders") do
    result = []
    result[0] = mimap2.list("", "*").map { |obj| obj.name }
    result[1] = mimap2.lsub("","*").map { |obj| obj.name }
    result
  end ) do |mcaller, data|
    mcaller.pass = data[0].sort == data[1].sort
  end,
  proxy(mimap2.method("create"),"INBOX/test1"),
  v(cb("Newly created folder in subscribed") do
    result = []
    result[0] = mimap2.list("", "*").map { |obj| obj.name }
    result[1] = mimap2.lsub("","*").map { |obj| obj.name }
    result
  end ) do |mcaller, data|
    mcaller.pass = data[0].sort == data[1].sort && data[1].include?("INBOX/test1")
  end,
  
  # disable autosubscribe for 'default' COS
  v(ZMProv.new('mc', 'default', 'zimbraDefaultFolderFlags', '""')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap1.method('logout')),
  proxy(mimap2.method('logout')),
  proxy(mimap1.method('disconnect')),
  proxy(mimap2.method('disconnect')), 
  DeleteAccount.new(testAccount1.name),
  DeleteAccount.new(testAccount2.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end

