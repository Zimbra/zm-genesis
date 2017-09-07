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
# zmprov account basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov" 
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov account zimbraFileVersioningEnabled/zimbraFileVersionLifetime test"

 
include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
cName = name + '1'
address = Model::TARGETHOST.cUser(name + 1.next.to_s, Model::DEFAULTPASSWORD)
mId = ZMProv.new('cc', cName).run[1].split(/\n/).first
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
  v(ZMProv.new('mc', cName, 'zimbraFileVersioningEnabled', 'TRUE')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
	
  v(ZMProv.new('ca', address.name, Model::DEFAULTPASSWORD, 'zimbraCOSId', mId)) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,
 
  v(ZMProv.new('ga', address.name, 'zimbraFileVersioningEnabled')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersioningEnabled:\s+TRUE/
  end,
  
  v(ZMProv.new('mc', cName, 'zimbraFileVersioningEnabled', 'FALSE')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ga', address.name, 'zimbraFileVersioningEnabled')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersioningEnabled:\s+FALSE/
  end,
  
  v(ZMProv.new('ma', address.name, 'zimbraFileVersioningEnabled', 'TRUE')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ga', address.name, 'zimbraFileVersioningEnabled')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersioningEnabled:\s+TRUE/
  end,
  
  v(ZMProv.new('mc', cName, 'zimbraFileVersionLifetime', '1m')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ga', address.name, 'zimbraFileVersionLifetime')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersionLifetime:\s+1m/
  end,
   
  v(ZMProv.new('ma', address.name, 'zimbraFileVersionLifetime', '2h')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('ga', address.name, 'zimbraFileVersionLifetime')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersionLifetime:\s+2h/
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
  Engine::Simple.new(Model::TestCase.instance, true).run  
end