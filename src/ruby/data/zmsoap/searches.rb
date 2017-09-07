#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
# Test zmsoap searches functions
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/zmprov"
require "action/verify"
require "action/zmsoap"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmsoap searches"

timeNow = Time.now.to_i.to_s
prefix = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
domain = Model::Domain.new("#{prefix}dom#{timeNow}.com")
testAccount1 = domain.cUser(prefix + 'acct1' + timeNow)
aliasAccount1 = domain.cUser(prefix + 'acctalias1' + timeNow)
testDl1 = domain.cUser(prefix + 'dl1' + timeNow)
aliasDl1 = domain.cUser(prefix + 'dlalias1' + timeNow)
testRes1 = domain.cUser(prefix + 'cal1' + timeNow)
aliasRes1 = domain.cUser(prefix + 'calalias1' + timeNow)

#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [
  # create test domain
  ZMProv.new('cd', domain.name),
  
  #create account and alias
  ZMProv.new('ca', testAccount1.name, Model::DEFAULTPASSWORD),
  ZMProv.new('aaa', testAccount1.name, aliasAccount1.name),
  
  #create list and alias
  ZMProv.new('cdl', testDl1.name),
  ZMProv.new('adla', testDl1.name, aliasDl1.name),
  
  #create resource and alias
  ZMProv.new('ccr', testRes1.name, Model::DEFAULTPASSWORD, 'displayName', testRes1.name.split('@').first, 'zimbraCalResType', 'Location'),
  ZMProv.new('aaa', testRes1.name, aliasRes1.name),

  v(ZMSoapXml.new('-z', "SearchDirectoryRequest/types=\"aliases,distributionlists,resources\" " +
                  "../domain=#{domain.name}")) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   !data[1].nil? &&
                   (aliases = data[1].elements['SearchDirectoryResponse'].get_elements('alias')).size == 3 &&
                   aliases.select do |a|
                     [a.attributes['name'], a.attributes['targetName'], a.attributes['type']].sort == [aliasAccount1.name, testAccount1.name, 'account'].sort
                   end.size == 1 &&
                   aliases.select do |a|
                     [a.attributes['name'], a.attributes['targetName'], a.attributes['type']].sort == [aliasDl1.name, testDl1.name, 'dl'].sort
                   end.size == 1 &&
                   aliases.select do |a|
                     [a.attributes['name'], a.attributes['targetName'], a.attributes['type']].sort == [aliasRes1.name, testRes1.name, 'calresource'].sort
                   end.size == 1
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