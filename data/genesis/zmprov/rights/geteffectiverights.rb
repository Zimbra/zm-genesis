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
#  Test case for getEffectiveRights(ger) command

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
current.description = "Test case for getEffectiveRights(ger) command"

prefix = 'zmprovrights'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 

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
  v(ZMProv.new('cd', "#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ca', "admin@#{prefix}domain.what.com",'test123','zimbraIsDelegatedAdminAccount','TRUE')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('grr', 'domain', "#{prefix}domain.what.com",'usr', "admin@#{prefix}domain.what.com",'accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

  # Basic ger
  v(ZMProv.new('ger','domain',"#{prefix}domain.what.com", "admin@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('Preset rights')\
                                && data[1].include?('accessGAL')
  end,

  # getEffectiveRights instead of ger
  v(ZMProv.new('getEffectiveRights')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,
  
  # Usage
  v(ZMProv.new('ger')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,

  v(ZMProv.new('cddl', "dynamiclist@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('grr', 'group', "dynamiclist@#{prefix}domain.what.com", 'usr', "admin@#{prefix}domain.what.com", 'modifyGroup')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ger','group', "dynamiclist@#{prefix}domain.what.com", "admin@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('Can set all attributes') &&
                                  data[1].include?('Can get all attributes')
  end,

# Delete acccount and domain
  v(ZMProv.new('da', "admin@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('ddl', "dynamiclist@#{prefix}domain.what.com")) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('dd', "#{prefix}domain.what.com")) do |mcaller, data|
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