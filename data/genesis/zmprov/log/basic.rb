#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 VMWare
#
#
# Test zmprov addAccountLogger(aal) , removeAccountLogger(ral) and help
#
if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end
require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"

include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmprov addAccountLogger(aal) , removeAccountLogger(ral) and help"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  # Adding Tests for bug 26545
  v(ZMProv.new('help', 'log')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("addAccountLogger") 
  end,
  
  #Create Account
  v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  #Add Account Logger with invalid level values
  v(ZMProv.new('aal', testAccount.name, 'zimbra.soap', 'Anything')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("invalid request: unknown Logging Level: Anything, valid values:")
  end,
  v(ZMProv.new('addAccountLogger', testAccountTwo.name, 'zimbra.soap', 'Anything')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("invalid request: unknown Logging Level: Anything, valid values:")
  end,
  
  #Add Account Logger with invalid Category values
  v(ZMProv.new('aal', testAccount.name, 'Anything', 'debug')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("invalid request: Log category Anything does not exist.")
  end,
  v(ZMProv.new('addAccountLogger', testAccountTwo.name, 'Anything', 'debug')) do |mcaller, data|
    mcaller.pass = data[0] == 2 && data[1].include?("invalid request: Log category Anything does not exist.")
  end,
  
  #Add Account Logger
  v(ZMProv.new('aal', testAccount.name, 'zimbra.soap', 'debug')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('addAccountLogger', testAccountTwo.name, 'zimbra.account', 'info')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  #Get Account Logger
  v(ZMProv.new('gal', testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("zimbra.soap=debug")
  end,
  v(ZMProv.new('getAccountLoggers', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("zimbra.account=info")
  end,
  
  #Get All Account Logger
  v(ZMProv.new('gaal')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount.name) && data[1].include?("zimbra.soap=debug") && data[1].include?(testAccountTwo.name) && data[1].include?("zimbra.account=info")
  end,  
  
  #Remove Account Logger
  v(ZMProv.new('ral', testAccount.name, 'zimbra.soap')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('removeAccountLogger', testAccountTwo.name, 'zimbra.account')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  #Get Account Logger
  v(ZMProv.new('gal', testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?("zimbra.soap=debug")
  end,
  v(ZMProv.new('getAccountLoggers', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?("zimbra.account=info")
  end,
  
  #Get All Account Logger
  v(ZMProv.new('gaal')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?(testAccount.name) && !data[1].include?("zimbra.soap=debug") && !data[1].include?(testAccountTwo.name) && !data[1].include?("zimbra.account=info")
  end,
  
  
  #Bug 31609 Adding test for gaal
  
  #Add Account Logger
  
  v(ZMProv.new('aal', testAccount.name, 'zimbra.soap', 'debug')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('addAccountLogger', testAccount.name, 'zimbra.account', 'info')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('aal', testAccountTwo.name, 'zimbra.doc', 'debug')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('addAccountLogger', testAccountTwo.name, 'zimbra.dav', 'warn')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
   #Get Account Logger
  v(ZMProv.new('gal', testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("zimbra.soap=debug") && data[1].include?("zimbra.account=info")
  end,
  v(ZMProv.new('getAccountLoggers', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("zimbra.doc=debug") && data[1].include?("zimbra.dav=warn")
  end,
  
  #Get All Account Logger
  v(ZMProv.new('gaal')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount.name) && ["zimbra.soap=debug","zimbra.account=info"].all? do |x|
    data[1].include?(x)
    end && data[1].include?(testAccountTwo.name) && ["zimbra.doc=debug","zimbra.dav=warn"].all? do |x|
    data[1].include?(x)
    end
  end,
  
  #Remove Account Logger
  v(ZMProv.new('ral', testAccount.name, 'zimbra.soap')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('removeAccountLogger', testAccount.name, 'zimbra.account')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ral', testAccountTwo.name, 'zimbra.doc')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('removeAccountLogger', testAccountTwo.name, 'zimbra.dav')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
   #Get Account Logger
  v(ZMProv.new('gal', testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?("zimbra.soap=debug") && !data[1].include?("zimbra.account=info")
  end,
  v(ZMProv.new('getAccountLoggers', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?("zimbra.doc=debug") && !data[1].include?("zimbra.dav=warn")
  end,
  
  #Get All Account Logger
  v(ZMProv.new('gaal')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?(testAccount.name) && ["zimbra.soap=debug","zimbra.account=info"].all? do |x|
    !data[1].include?(x)
    end && !data[1].include?(testAccountTwo.name) && ["zimbra.doc=debug","zimbra.dav=warn"].all? do |x|
    !data[1].include?(x)
    end
  end,
   
  #END Bug 31609 Addding test for gaal
  
  
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