

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
# zmprov notebook basic test

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
current.description = "Zmprov Notebook Basic test"

 
include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [     
	#Init Notebook	 
	v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
      mcaller.pass = data[0] == 0
	end,
	
	v(ZMProv.new('in',  Model::TARGETHOST)) do |mcaller, data|
      mcaller.pass = data[1].include?('no')
	end,
 
    v(ZMProv.new('in',  testAccount.name 
      )) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('Initializing')
	end,
    v(ZMProv.new('impn',  testAccount.name, 
      testAccount.password, 'hi', 'hi')) do |mcaller, data|
      mcaller.pass = data[0] == 1
	end,
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