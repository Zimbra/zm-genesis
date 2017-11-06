#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# zmprov list basic test

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
current.description = "Zmprov Distribution List Basic test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)
testAccountFour = Model::TARGETHOST.cUser(name+'4', Model::DEFAULTPASSWORD)
testAccountFive = Model::TARGETHOST.cUser(name+'5', Model::DEFAULTPASSWORD)  
include Action
#
# Setup
#
current.setup = [
   
]
#
# Execution
#
current.action = [
  
  v(ZMProv.new('help')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /zmprov help list\s+help on distribution list-related commands/
  end,
  
  v(ZMProv.new('help', 'list')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("addDistributionListAlias")
  end,
  #Create Distribution List
  v(ZMProv.new('cdl',testAccount)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('cdl',testAccountFour)) do |mcaller, data|	
     mcaller.pass = data[0] == 0
  end,
  # Add Distribution List Member
  v(ZMProv.new('CreateAccount', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,	
  v(ZMProv.new('adlm', testAccount, testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  # Get Distribution List
  v(ZMProv.new('gdl', testAccount)) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDistributionList') &&
                   !(members = data[1][/members\n(.*)/m, 1]).nil? &&
                   members.split(/\n/) == [testAccountThree.name]
  end,
     
  # Get Distribution List Membership
  v(ZMProv.new('gdlm', testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccountThree)
  end,
  
  # Get All Distribution Lists
  v(ZMProv.new('gadl')) do |mcaller, data|	  
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount)
  end,
  
  v(ZMProv.new('adla',testAccount, testAccountTwo)) do |mcaller, data|  
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('adlm', testAccountFour, testAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  # Modify Distribution List
  v(ZMProv.new('mdl', testAccount, 'zimbraMailStatus', 'disabled')) do |mcaller, data|	
    mcaller.pass = data[0] == 0 
  end,
  
  # Remove Distribution List Member
  v(ZMProv.new('rdlm', testAccount, testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,	
  
  # Remove Distribution List Alias
  v(ZMProv.new('rdla',testAccount, testAccountTwo)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
  end,
  
  # Create duplicate dls
  v(ZMProv.new('cdl',testAccountThree)) do |mcaller, data|  
    mcaller.pass = data[0] != 0 && data[1] =~ /email address already exists: #{testAccountThree.to_s}/
  end,
  v(ZMProv.new('cdl',testAccount)) do |mcaller, data| 
    mcaller.pass = data[0] != 0 && data[1] =~ /email address already exists: #{testAccount.to_s}/
  end,
  
  # Delete Distribution List
  v(ZMProv.new('ddl',testAccount)) do |mcaller, data|	
    mcaller.pass = data[0] == 0  
  end,
  
  v(ZMProv.new('da', testAccountThree.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  #Bug 34268  
  v(ZMProv.new('cdl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,	
  v(ZMProv.new('adla', testAccountFive.name, 'dlalias'+testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('gdl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?('zimbraMailAlias: dlalias'+testAccountFive.name))
  end,
  v(ZMProv.new('rdla', testAccountFive.name, 'dlalias'+testAccountFive.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('gdl', testAccountFive.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?('zimbraMailAlias: '+testAccountFive.name))
  end,  
  #END Bug 34268
   
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