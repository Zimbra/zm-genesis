#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# zmprov cto basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"
require "action/block"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov counting object test cases"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub('/', '')
timeNow = Time.now.to_i.to_s
serviceOne = name + 'service' + '1' + timeNow
providerOne = name + 'provider' + '1' + timeNow

include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
	
  #Bug 46624
  v(ZMProv.new('cto', '-h')) do |mcaller,data|
  mcaller.pass = data[0] != 0 && data[1].include?("service.INVALID_REQUEST")
  end,
  
  v(ZMProv.new('cto')) do |mcaller,data|
  mcaller.pass = data[0] != 0 &&
                 data[1].include?("usage:  countObjects(cto) {userAccount|account|alias|dl|domain|cos|server|calresource|" + 
                                  "accountOnUCService|cosOnUCService|domainOnUCService|internalUserAccount|" +
                                  "internalArchivingAccount} [-d {domain|id}] [-u {UCService|id}]")
  end,

#  v(ZMProv.new('-l', 'cto', 'userAccounts')) do |mcaller,data|
#  iResult = data[1]  
#   if(iResult[1] =~ /Data\s+:/)
#      iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
#   end
#  
#  end,
 
  ['account', 'alias', 'dl', 'domain', 'cos', 'server', 'calresource', 'internalUserAccount', 'internalArchivingAccount'].map do |x|
    v(ZMProv.new('cto', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] =~ /^\d+$/
    end 
  end,
  
# Test cto works with '-l' also
  ['account', 'alias', 'dl', 'domain', 'cos', 'server', 'calresource', 'internalUserAccount', 'internalArchivingAccount'].map do |x|
    v(ZMProv.new('-l', 'cto', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] =~ /^\d+$/
    end 
  end
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
