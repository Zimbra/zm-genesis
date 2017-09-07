#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Zimbra
#
# bug #58624, #67663

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/decorator"
require "action/zmprov"
require "action/zmcontrol"
require "action/zmlocalconfig"
require "action/zmamavisd"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP error response limit"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = d
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
  
  # set the default IMAP error counter
  ZMLocalconfig.new('-e imap_max_consecutive_error=5'),
  ZMMailboxdctl.new("restart"),
  #cb("wait") {sleep(15)},
  ZMMailboxdctl.waitForMailboxd(),
  
  cb("login") do
    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mimap.login(testAccount.name, testAccount.password)
  end,
  
  cb("only consecutive no/bad should be counted") do
    begin
    mimap.delete("INBOX/") rescue 
    mimap.rename("INNBOX/", "NNBox") rescue
    mimap.method('send_command').call("noop fdgdg") rescue
    mimap.select("=43") rescue # 4th Bad/No action
    mimap.select("INBOX") # OK response
    mimap.create("INBOX/")
    end
  end,
  
  v(cb("Connection should not be dropped") do
        Kernel.sleep(11)
        mimap.responses.keys
      end) do |caller, data|
    caller.pass = !data.include?("BYE")
  end,
  
  cb("drop connection after 5 no/bad responses") do
    begin
    mimap.create("INBOX/") rescue # 2nd Nad/No in a row
    mimap.delete("INBOX/") rescue
    mimap.rename("INNBOX/", "NNBox") rescue
    mimap.method('send_command').call("noop fdgdg") # 5th Bad/No in a row
    end
    
  end,
  v(cb("Connection should be dropped") do
        Kernel.sleep(11)
        mimap.responses.keys
      end) do |caller, data|
    caller.pass = data.include?("BYE")
  end,
  
  # reset counter for unlimited for other tests
  ZMLocalconfig.new('-e imap_max_consecutive_error=0'),
  ZMMailboxdctl.new("restart"),
  #cb("wait") {sleep(15)},
  ZMMailboxdctl.waitForMailboxd(),
  
  cb("login again") do
    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mimap.login(testAccount.name, testAccount.password)
  end,
  
  cb("unlimited errors now") do
    begin
    mimap.delete("INBOX/") rescue 
    mimap.rename("INNBOX/", "NNBox") rescue
    mimap.method('send_command').call("noop fdgdg") rescue
    mimap.create("INBOX/")
    end
  end,
  
  v(cb("Connection should not be dropped - unlimited") do
        Kernel.sleep(11)
        mimap.responses.keys
      end) do |caller, data|
    caller.pass = !data.include?("BYE")
  end,
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
