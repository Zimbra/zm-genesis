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
# zmprov search basic test

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
current.description = "Zmprov Search Basic test"

 
include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testResource1 = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
testResource2 = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)

 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [     
  #Create Account
  v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Auto Complete
  v(ZMProv.new('acg', Model::DOMAIN.to_s, testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount)
  end,

  v(ZMProv.new('acg', Model::DOMAIN.to_s, name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount)
  end,

  #Search GAL
  v(ZMProv.new('sg', Model::DOMAIN.to_s, testAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount)
  end,

  #Search CalendarResource
  v(ZMProv.new('scr', '-v', Model::TARGETHOST, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('searchCalendarResources can only be used with  "zmprov -l/--ldap"')
  end,

  v(ZMProv.new('scr', Model::TARGETHOST, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('searchCalendarResources can only be used with  "zmprov -l/--ldap"')
  end,	

  v(ZMProv.new('-l', 'scr', '-v', Model::DOMAIN.to_s, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
 
  v(ZMProv.new('-l', 'scr', Model::DOMAIN.to_s, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,		

  v(ZMProv.new('ccr', testResource1, testResource1.password, 'displayName',testResource1,'zimbraCalResType','Location')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('ccr', testResource2, testResource2.password, 'displayName',testResource2,'zimbraCalResType','Equipment')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('-l', 'scr', '-v', Model::DOMAIN.to_s, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testResource1) && data[1].include?(testResource2)
  end,

  v(ZMProv.new('-l', 'scr', Model::DOMAIN.to_s, '2>&1')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testResource1) && data[1].include?(testResource2)
  end,
  # CalendarResource search case ends here.

  v(ZMProv.new('sg', Model::DOMAIN.to_s, name+'3')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?(testAccount)
  end,

  #Search Account Bug 67535: zmprov seachAccount: ExceptionInInitializerError on searching account.
  v(ZMProv.new('sa', 'cn='+name+'*')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(testAccount)
  end, 
  v(ZMProv.new('sa', '-v', 'cn='+name+'*')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('zimbraMailSpamLifetime')
  end,
  # End Search Account

  #Delete Account
  v(ZMProv.new('da', testAccount.name)) do |mcaller, data|
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
  Engine::Simple.new(Model::TestCase.instance, true).run  
end