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
current.description = "Zmprov account identities test"

 
include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
cName = name + '1'
address = Model::TARGETHOST.cUser(name + 1.next.to_s, Model::DEFAULTPASSWORD)
mId = ZMProv.new('cc', cName).run[1].split(/\n/).first
maxIdentities = 2
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
  v(ZMProv.new('gc', cName, 'zimbraIdentityMaxNumEntries')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /zimbraIdentityMaxNumEntries:\s+20\s*$/
  end,
  
  v(ZMProv.new('mc', cName, 'zimbraIdentityMaxNumEntries', maxIdentities)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gc', cName, 'zimbraIdentityMaxNumEntries')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraIdentityMaxNumEntries:\s+#{maxIdentities}\s*$/
  end,
  
  v(ZMProv.new('ca', address.name, Model::DEFAULTPASSWORD, 'zimbraCOSId', mId)) do |mcaller, data| 
    mcaller.pass = data[0] == 0
  end,
 
  v(ZMProv.new('ga', address.name, 'zimbraIdentityMaxNumEntries')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /zimbraIdentityMaxNumEntries:\s+#{maxIdentities}\s*$/ 
  end,

  (1..maxIdentities - 1).to_a.map do |x|
    v(ZMProv.new('cid', address.name, "identity#{x}")) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end
  end,

  v(ZMProv.new('cid', address.name, "identity#{maxIdentities.to_s}")) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1] =~ /ERROR: account.TOO_MANY_IDENTITIES/
  end,

  v(ZMProv.new('ma', address.name, 'zimbraIdentityMaxNumEntries', maxIdentities + 1)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('cid', address.name, "identity#{maxIdentities.to_s}")) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('gid', address.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select do |w|
                     w =~ /zimbraPrefIdentityName/
                   end.collect do |w|
                     w[/zimbraPrefIdentityName:\s+(\S+)/, 1]
                   end.length == maxIdentities + 1
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