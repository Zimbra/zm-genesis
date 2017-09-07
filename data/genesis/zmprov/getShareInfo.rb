#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
#
#  Test case for gsi (getShareInfo) command

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"
require "action/verify"
require "action/command"
require "action/runcommand"
require "action/zmprov"

include Action
name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for gsi (getShareInfo) command"
testAccount = Model::TARGETHOST.cUser(name,  Model::DEFAULTPASSWORD)
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  #Create Account
  CreateAccount.new(testAccount.name, testAccount.password),  
 
  #Share Calendar and verify
  v(ZMProv.new('sm', testAccount.name,'mfg','/Calendar','public','r' )) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

  v(ZMProv.new('gsi', testAccount.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('/Calendar')
  end,

# Deprecating below as Notebook not supported now 
#  #Share Notebook and verify
#  v(ZMProv.new('sm', testAccount.name,'mfg','/Notebook','public','r' )) do |mcaller, data|
#   mcaller.pass = data[0] == 0 
#  end,
#
#  v(ZMProv.new('gsi', testAccount.name)) do |mcaller, data|
#   mcaller.pass = data[0] == 0 && data[1].include?('/Notebook')
#  end,

 #Share Briefcase and verify
  v(ZMProv.new('sm', testAccount.name,'mfg','/Briefcase','public','r' )) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

  v(ZMProv.new('gsi', testAccount.name)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('/Briefcase')
  end,

# getShareInfo instead of gsi
  v(ZMProv.new('getShareInfo', 'foo@foo.com')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_ACCOUNT')
  end,
  
# gsi with invalid name
  v(ZMProv.new('gsi', 'foo@foo.com')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_ACCOUNT')
  end,

# gsi with invalid address
  v(ZMProv.new('gsi', 'onlyfoo')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_ACCOUNT (no such account: onlyfoo)')
  end,
]
#
# Tear Down
#
current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end