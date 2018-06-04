#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2007 Zimbra
#
#
# IMAP authentication test cases
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"

require "action/block"
require "action/proxy"
require "action/zmcontrol"
require "action/verify"
require "action/zmprov"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Auth No SSL"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)


#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  if Model::TARGETHOST.proxy
    [Action::ZMProv.new('mcf', 'zimbraReverseProxyImapStartTlsMode', 'on'),
    ]
  else
    Action::ZMProv.new('ms', Model::TARGETHOST, 'zimbraImapCleartextLoginEnabled', 'TRUE')
  end,
  Action::CreateAccount.new(testAccount.name,testAccount.password),
  v(
    cb("Login Test",120) do
      mimap = Net::IMAP.new(Model::TARGETHOST)
      result = mimap.login(testAccount.name, testAccount.password)
      begin
        mimap.logout
        mimap.disconnect
      rescue
      end
      result
    end
  ) { |mcaller, data|
    mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
      (data.name == 'OK') &&
      (data.raw_data.include?('completed'))
  },
  Action::DeleteAccount.new(testAccount.name),
  #Action::ZMProv.new('ms', Model::TARGETHOST, 'zimbraImapCleartextLoginEnabled', 'FALSE'),

]

#
# Tear Down
#
current.teardown = [

]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance,false).run
end