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
#  Test case for grantRight(grr) command

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
current.description = "Test case for grantRight(grr) command"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
timeNow = Time.now.to_i.to_s
testDomain = [name + timeNow, 'dom', 'com'].join('.')

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
  v(ZMProv.new('cd', testDomain)) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].chomp =~ /[\da-f\-]{36}/
  end,
  v(ZMProv.new('ca', aAcct = "admin@#{testDomain}", 'test123', 'zimbraIsDelegatedAdminAccount', 'TRUE')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].chomp =~ /[\da-f\-]{36}/
  end,

  # Basic grr
  v(ZMProv.new('grr', 'domain', testDomain, 'usr', aAcct, 'accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,

 # grantRight instead of grr
  v(ZMProv.new('grantRight', 'domain',testDomain, 'usr', aAcct, 'domainAdminRights')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  
  # Usage
  v(ZMProv.new('grr')) do |mcaller, data|
   mcaller.pass = data[0] != 0 && data[1].include?('usage')
  end,
  
  v(ZMProv.new('cdl', "dl1@#{testDomain}"))  do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].chomp =~ /[\da-f\-]{36}/
  end,
  
  v(ZMProv.new('cdl', "sub-dl1@#{testDomain}"))  do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].chomp =~ /[\da-f\-]{36}/
  end,
  
  v(ZMProv.new('adlm', "dl1@#{testDomain}", "sub-dl1@#{testDomain}"))  do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", aAcct, 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "sub-dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@nodomain.com", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('grr', 'dl', "dl1@#{testDomain}", 'dom', testDomain, 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", aAcct, 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "sub-dl1@#{testDomain}", aAcct, 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /DENIED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "sub-dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /DENIED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@nodomain.com", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /DENIED/
  end,
  
  #suppress inheritance
  v(ZMProv.new('grr', 'dl', "dl1@#{testDomain}", 'dom', testDomain, '^sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@nodomain.com", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /DENIED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "sub-dl1@#{testDomain}", "johnDoe@nodomain.com", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /DENIED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "sub-dl1@#{testDomain}", "johnDoe@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "dl1@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,
  
  v(ZMProv.new('checkRight', 'dl', "dl1@#{testDomain}", "sub-dl1@#{testDomain}", 'sendToDistList')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /ALLOWED/
  end,

=begin
  # Delete acccount and domain
  v(ZMProv.new('da', aAcct)) do |mcaller, data|
   mcaller.pass = data[0] == 0 
  end,
  v(ZMProv.new('dd', testDomain)) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
=end
 
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