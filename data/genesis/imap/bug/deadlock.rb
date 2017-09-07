#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
# IMAP deadlock bug 18951
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/waitqueue"
require "action/decorator"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Deadlock"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap) 
mImaps = Array.new(15) { |i| Action::Decorator.new }
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
  CreateAccount.new(testAccount.name,testAccount.password),
   
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  proxy(mimap.method('select'), 'INBOX'),
   
  cb("Initialize imap connection") do
    mImaps.each do |x|
      x.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    end
  end,

  mImaps.map do |x|
    cb("Create connection") do 
      x.login(testAccount.name, testAccount.password)
      x.select('INBOX')
    end
  end,
  
  cb("time") {Kernel.sleep(1)},
  # check connection - should be dropped
  v(proxy(mimap.method('list'),"","*"), 60) do  |mcaller, data|
    mcaller.pass = data.class == Errno::EPIPE
  end,
                  
  mImaps.map do |x|
    cb("Clean Up") do
      x.logout
      x.disconnect
    end
  end
]

#
# Tear Down
#
current.teardown = [      
  proxy(mimap.method('disconnect')), 
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
