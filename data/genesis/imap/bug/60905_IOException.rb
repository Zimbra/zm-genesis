#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Bug #60905 Occasional IOException on active disconnect by IMAP client
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/runcommand"
require "action/decorator"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IOException on active disconnect by IMAP client"

#name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
#testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
#
#mImaps = Array.new(1000) { |i| Action::Decorator.new }

include Action

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
  #CreateAccount.new(testAccount.name,testAccount.password),
  ##ZMProv.new('aal', testAccount.name, 'zimbra.imap', 'trace'),
  # 
  #mImaps.map do |x|
  #  [cb("Create connection") do
  #    x.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
  #    x.login(testAccount.name, testAccount.password)
  #    x.select('INBOX')
  #  end,
  #    ## TODO - use log checker
  #  v(RunCommand.new('tail', 'root', '-n25', File.join(Command::ZIMBRAPATH, 'log', 'mailbox.log'))) do | mcaller, data |
  #    mcaller.pass = !data[1].match(/^.*ERROR.*IOException.*$/)
  #  end
  #  ]
  #end
]

#
# Tear Down
#
#
current.teardown = [     
  #DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 


