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
#  Test case for getGrants (gg) command

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
current.description = "Test case for getGrants(gg) command"
prefix = 'test'

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
 
  # Basic grr
  v(ZMProv.new('gg','-t','domain','testdomain.what.com','-g','usr','admin@testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

  # getGrants instead of gg
  v(ZMProv.new('getRight')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,
  
  # Usage
  v(ZMProv.new('gg')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,
  
  v(ZMProv.new('cddl', "dynamiclist@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('grr', 'group', "dynamiclist@#{prefix}domain.what.com", 'usr', "admin@#{prefix}domain.what.com", 'modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('gg', '-t', 'group', "dynamiclist@#{prefix}domain.what.com", '-g', 'usr', "admin@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

# Delete acccount and domain
  v(ZMProv.new('da', 'admin@testdomain.what.com')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ddl', "dynamiclist@#{prefix}domain.what.com")) do |mcaller, data|
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