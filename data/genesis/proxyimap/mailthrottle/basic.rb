#!/usr/bin/ruby -w
#
# $File: //depot/zimbra/JUDASPRIEST/ZimbraQA/data/genesis/proxyimap/mailthrottle/basic.rb $ 
# $DateTime: 2014/08/01 20:28:23 $
#
# $Revision: #1 $
# $Author: quanah $
# 
# Basic test for user and ip limit throttle 
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/command"
require "action/block"
require "action/runcommand"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "net/pop"
require "action/pop"

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Basic test for user and ip limit throttle"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

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
  CreateAccount.new(testAccount.name,testAccount.password),
  if(Model::TARGETHOST.proxy == true)
    [
      # enable User login limit 
      RunCommand.new('zmprov', Command::ZIMBRAUSER, 'mcf zimbraReverseProxyUserLoginLimit 1'),
      RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'restart'),
      cb("Sleep 10 seconds", 120) { Kernel.sleep(10)},
      
      v(cb("First login - should pass") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
          mResult = mTemp.login(testAccount.name, testAccount.password)
          mTemp.logout
          mTemp.disconnect 
          mResult
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::TaggedResponse && data.name == 'OK'
      end,
  
      v(cb("Second login - should fail") do
          mTemp = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true) 
          mTemp.login(testAccount.name, testAccount.password)
        end) do |mcaller, data|
          mcaller.pass = data.class == Net::IMAP::NoResponseError && data.message == "LOGIN failed"
      end,
      
      v(cb("Third login - should fail") do
          mTemp = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
          mTemp.tls = true
          mTemp.start(testAccount.name, testAccount.password)end) do |mcaller, data|
          mcaller.pass = data.class == Net::POPAuthenticationError && data.message.include?("Login rejected for this user")
      end,
  
      #disable User login limit
      RunCommand.new('zmprov', Command::ZIMBRAUSER, 'mcf zimbraReverseProxyUserLoginLimit 0'),
      RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'restart'),
      cb("Sleep 10 seconds", 120) { Kernel.sleep(10)},
    ]
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

