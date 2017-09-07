#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
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
require "net/pop"; require "action/pop"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP and IMAP login responses"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

include Action
Net::IMAP.add_authenticator('PLAIN', Net::IMAP::PlainAuthenticator)
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

  [testAccount.name, 'fake'].map do |x|
    v(cb("IMAP Login Plain") do
      mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
      mResult = mTemp.login(x, "fake")
      mTemp.logout
      mTemp.disconnect
      mResult
    end) do |mcaller, data|
      mcaller.pass = data.class == Net::IMAP::NoResponseError &&
                     data.message == 'LOGIN failed'
    end
  end,

  [testAccount.name, 'fake'].map do |x|
    v(cb("IMAP AUTH Plain") do
      mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
      mResult = mTemp.authenticate('PLAIN', x, "fake")
      mTemp.logout
      mTemp.disconnect
      mResult
    end) do |mcaller, data|
      mcaller.pass = data.class == Net::IMAP::NoResponseError &&
                     data.message == 'AUTHENTICATE failed'
    end
  end,

  [testAccount.name, 'fake'].map do |x|
    v(cb("POP3 Login Plain") do
      mTemp = Net::POP3.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
      mResult = mTemp.start(x, "fake")
      mTemp.finish
      mResult
    end) do |mcaller, data|
      mcaller.pass = data.class == Net::POPAuthenticationError &&
                     data.message == "-ERR LOGIN failed"
    end
  end,

  [testAccount.name, 'fake'].map do |x|
    v(cb("POP3 AUTH Plain") do
      mTemp = Net::POP3::AuthPlain.new(Model::TARGETHOST, *Model::TARGETHOST.pop)
      mResult = mTemp.start(x, "fake", '')
      mTemp.finish
      mResult
    end) do |mcaller, data|
      mcaller.pass = data.class == Net::POPAuthenticationError &&
                     data.message == "-ERR authentication failed: LOGIN failed"
    end
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
