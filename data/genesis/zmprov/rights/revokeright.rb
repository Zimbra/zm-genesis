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
#  Test case for revokeRight(rvr) command

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/verify"
require "action/zmprov"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for revokeRight(rvr) command"

#
# Setup
#
current.setup = [
 

]
#
# Execution
#
current.action = [

  #Create domain and admin account
  v(ZMProv.new('cd','testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ca', 'admin@testdomain.what.com','test123','zimbraIsDelegatedAdminAccount','TRUE')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
   v(ZMProv.new('grr', 'domain','testdomain.what.com','usr','admin@testdomain.what.com','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
 
  # Basic rvr
  v(ZMProv.new('rvr','domain','testdomain.what.com','usr','admin@testdomain.what.com','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('rvr','domain','testdomain.what.com','usr','admin@testdomain.what.com','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_GRANT ') 
  end,
  
  # rvr on dynamic lists
  v(ZMProv.new('cddl', "dynamiclist@testdomain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('grr', 'group', "dynamiclist@testdomain.what.com", 'usr', "admin@testdomain.what.com", 'modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('rvr','group','dynamiclist@testdomain.what.com','usr','admin@testdomain.what.com','modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('rvr','group','dynamiclist@testdomain.what.com','usr','admin@testdomain.what.com','modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_GRANT ') 
  end,
  
  # revokeRight instead of rvr
  v(ZMProv.new('revokeRight')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage') 
  end,

  # Invalid option
  v(ZMProv.new('rvr','-l')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,



  # Delete acccount and domain
  v(ZMProv.new('da', 'admin@testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ddl', "dynamiclist@testdomain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('dd','testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0
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