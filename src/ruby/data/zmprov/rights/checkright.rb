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
#  Test case for checkRight(ckr)command

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
current.description = "Test case for checkRight(ckr) command"

#
# Setup
#
current.setup = [
 

]
#
# Execution
#
current.action = [

  # Create an admin account and grant right
  v(ZMProv.new('cd','testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ca', 'admin@testdomain.what.com','test123','zimbraIsDelegatedAdminAccount','TRUE')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('grr', 'domain','testdomain.what.com','usr','admin@testdomain.what.com','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
 
  # Basic Check right  
  v(ZMProv.new('ckr','domain','testdomain.what.com','admin@testdomain.what.com','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('ALLOWED')\
                               && data[1].include?('Via:')\
                               && data[1].include?('target type  : domain')\
                               && data[1].include?('target       : testdomain.what.com')\
                               && data[1].include?('grantee type : usr')\
                               && data[1].include?('grantee      : admin@testdomain.what.com')\
                               && data[1].include?('right        : accessGAL')                               
  end,

  # Check any right  
  v(ZMProv.new('ckr','domain','testdomain.what.com','admin@testdomain.what.com','setAccountPassword')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('DENIED')\
  end,

  # Basic/Usage grd
  v(ZMProv.new('ckr')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage:  checkRight(ckr)') 
  end,
  v(ZMProv.new('checkRight')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage:  checkRight(ckr)') 
  end,
  
  # Invalid option
  v(ZMProv.new('ckr','-l')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage') 
  end,
  
  # dynamic groups
  v(ZMProv.new('cddl','testdynamiclist@testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('grr', 'group', 'testdynamiclist@testdomain.what.com', 'usr', 'admin@testdomain.what.com', 'modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ckr', 'group', 'testdynamiclist@testdomain.what.com', 'admin@testdomain.what.com', 'modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('ALLOWED')
  end,
 
  # Delete acccount and domain
  v(ZMProv.new('da', 'admin@testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ddl','testdynamiclist@testdomain.what.com')) do |mcaller, data|
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