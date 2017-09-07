#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 Zimbra
#
# bug #51171

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/decorator"
require "action/zmprov"
require "action/zmlocalconfig"
require "action/zmamavisd"
require "action/verify"
require "action/simpleconnect"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP error response limit"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

scon = d
port = 110

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
  ZMLocalconfig.new('-e pop3_max_consecutive_error=5'),
  ZMMailboxdctl.new("restart"),
  ZMMailboxdctl.waitForMailboxd(),
  
  #cb("wait") {sleep(5)},
  
  v(cb("Empty command") do
    scon = Action::SimpleConnect.new(Model::TARGETHOST, port)
    scon.send_str("user #{testAccount.name}")
    scon.send_str("pass #{testAccount.password}")
    scon.send_str('retr 4345')
    scon.send_str('pass xvTdsf#$sd')
    scon.send_str('')
    scon.send_str("user #{testAccount.name}")
    scon.send_str('something')
    end ) do |mcaller, data|
      mcaller.pass = data.response.include?("Dropping connection due to too many bad commands")
  end,

  v(cb("Connection should be dropped") do
        Kernel.sleep(11)
        scon.send_str('list')
      end) do |caller, data|
    caller.pass = data.response.nil?
  end,
  
  ## reset counter for unlimited for other tests
  ZMLocalconfig.new('-e pop3_max_consecutive_error=0'),
  ZMMailboxdctl.new("restart"),
  ZMMailboxdctl.waitForMailboxd()

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

