#!/usr/bin/ruby -w
#
# = data/imap/extension/idle.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP Extension idle test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/decorator"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP IDLE test"

name = 'iext'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)


mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
include Action

 
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
  proxy(mimap.method('put_string'),"A1 IDLE\r\n"), 
  v(proxy(mimap.method('send_command'),'login'), &IMAP::ParseError),   
  proxy(mimap.method('login'),testAccount.name,testAccount.password), 
  proxy(mimap.method('put_string'),"A1 IDLE\r\n"), 
  #break server due to bug comment out fornow
  #decorator(proxy(mimap.method('put_string'), "#{'DONE'*10000000}\r\n"), Decorator::NODUMP), 
  v(cb("IDLE DONE", 180) do
      Kernel.sleep(60)
      result = 'pass'
      begin
        mimap.method('put_string').call("DONE\r\n")
      rescue
        result = 'fail'
      end
      result
    end) do |mcaller, data|
      mcaller.pass = (data == 'pass')
  end,
  proxy(Kernel.method('sleep'),10),  
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),   
  proxy(mimap.method('disconnect')),   
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'   
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
