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
require "action/zmsoap"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Distribution List Membership test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)

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
  #Create Distribution List
  v(ZMProv.new('cdl',testAccount)) do |mcaller, data|	
    mcaller.pass = data[0] == 0 && data[1] =~ /(\d|[a-f]|-){36}$/
  end,
    
  v(ZMProv.new('cdl',testAccount.name.gsub(/^./, ''))) do |mcaller, data|	
     mcaller.pass = data[0] == 0 && data[1] =~ /(\d|[a-f]|-){36}$/
  end,
    
  # Add account 2 to dl testAccount
  v(ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /(\d|[a-f]|-){36}$/
  end,
  v(ZMProv.new('adlm', testAccount, testAccountTwo)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  # Add account 3 to dl estAccount
  v(ZMProv.new('CreateAccount', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /(\d|[a-f]|-){36}$/
  end,
  v(ZMProv.new('adlm', testAccount.name.gsub(/^./, ''), testAccountThree)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
     
  # Get Distribution List Membership
  v(ZMSoapXml.new('-m', testAccountTwo.name, '-p', testAccountTwo.password, '-t', 'account',
                  'GetDistributionListMembersRequest', "dl=#{testAccount.name.gsub(/^./, '')}")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].nil? &&
                   !(response = data[1].elements['GetDistributionListMembersResponse']).nil? &&
                   !(members = response.get_elements('dlm').collect {|w| w.text}).nil? &&
                   members.include?(testAccountThree.name)
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