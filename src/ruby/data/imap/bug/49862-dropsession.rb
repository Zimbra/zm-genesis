#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug #49862 drop IMAP sessions for deleted folders
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Drop IMAP sessions for deleted folders"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action
#Net::IMAP.debug = true
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [   
  proxy(mimap1.method('login'),testAccount.name,testAccount.password),
  proxy(mimap1.method('create'),"INBOX/delete") ,
  proxy(mimap1.method('select'),"INBOX/delete") , 
  
  proxy(mimap2.method('login'),testAccount.name,testAccount.password),
  DeleteVerify.new(mimap2, "INBOX/delete"),
  
  # check connection - should be dropped
  v(proxy(mimap1.method('list'),"","*"), 60) do  |mcaller, data|
     mcaller.pass = data.class == Errno::EPIPE
   end,
  
  # TODO - use log checker
  v(RunCommand.new('tail', 'root', '-n35', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))) do | mcaller, data |
     mcaller.pass = !data[1].include?('NO_SUCH_FOLDER') && !data[1].include?("NoSuchItemException")
  end,

 ]

#
# Tear Down
#
#
current.teardown = [     
  proxy(mimap1.method('logout')),
  proxy(mimap1.method('disconnect')),
  proxy(mimap2.method('logout')),
  proxy(mimap2.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 

