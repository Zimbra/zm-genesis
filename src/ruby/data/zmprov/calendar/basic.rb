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
# zmprov calendar basic test

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
current.description = "Zmprov Calendar Basic test"


include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
renamedAccount = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'4', Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
	#Create Calendar
	v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,
	v(ZMProv.new('ccr', testAccountTwo, testAccountTwo.password, 'displayName','foo',
	 'zimbraCalResType','Location','zimbraCalResAutoAcceptDecline','TRUE','zimbraCalResAutoDeclineIfBusy','TRUE')) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,
	
	#BUG 10632	
	v(ZMProv.new('ccr', testAccountThree, testAccountThree.password, 'displayName','third',
	 'zimbraCalResType','Location','zimbraCalResAutoAcceptDecline','TRUE','zimbraCalResAutoDeclineIfBusy','TRUE')) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,
	
	v(ZMProv.new('scr', Model::TARGETHOST.to_s)) do |mcaller, data|
	 mcaller.pass = data[0] != 0 && data[1].include?("searchCalendarResources can only be used with  \"zmprov -l/--ldap\"")
	end,
	
	v(ZMProv.new('-l','scr', Model::TARGETHOST.to_s)) do |mcaller, data|
	 mcaller.pass = data[0] == 0 && !data[1].include?("Exception") && data[1].include?(testAccountThree)
	end,	
	#END BUG 10632

	#Get all calendar
	v(ZMProv.new('gacr','-v')) do |mcaller, data|
  mcaller.pass = data[0] == 0
	end,
	v(ZMProv.new('gcr', testAccountTwo)) do |mcaller, data|
	mcaller.pass = data[1].include?('displayName: foo')
	end,

  #purgeAccountCalendarCache(pacc)
  v(ZMProv.new('pacc',testAccount.name)) do |mcaller, data|
  mcaller.pass = data[0] == 0
  end,

	#Modify calendar
	v(ZMProv.new('mcr', testAccountTwo, 'displayName', 'fee')) do |mcaller, data|
  mcaller.pass = data[0] == 0
	end,
	# After modification
	v(ZMProv.new('gcr', testAccountTwo)) do |mcaller, data|
  mcaller.pass = data[1].include?('displayName: fee')
	end,

	v(ZMProv.new('rcr', testAccountTwo, renamedAccount)) do |mcaller, data|
  mcaller.pass = data[0] == 0
	end,

	# After move
	v(ZMProv.new('gcr', renamedAccount)) do |mcaller, data|
  mcaller.pass = data[1].include?('displayName: fee')
	end,

	# After move, none should exist
  v(ZMProv.new('gcr', testAccountTwo)) do |mcaller, data|
  mcaller.pass = data[0] == 2
	end,

  v(ZMProv.new('dcr', renamedAccount)) do |mcaller, data|
  mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gcr', renamedAccount)) do |mcaller, data|
  mcaller.pass = !data[1].include?('displayName: fee')
  end,

  #Delete calendar
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
  Engine::Simple.new(Model::TestCase.instance).run
end