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
# zmprov cos basic test

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
current.description = "Zmprov Cos zimbraFileVersioningEnabled/zimbraFileVersionLifetime test"

 
include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [     
	#Create COS
	v(ZMProv.new('cc', name)) do |mcaller, data|	
	 mcaller.pass = data[0] == 0
	end,
	
	v(ZMProv.new('mc', name, 'zimbraFileVersioningEnabled', 'TRUE')) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,
  
  v(ZMProv.new('gc', name, 'zimbraFileVersioningEnabled')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersioningEnabled:\s+TRUE/
  end,
  
  v(ZMProv.new('mc', name, 'zimbraFileVersioningEnabled', 'FALSE')) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('gc', name, 'zimbraFileVersioningEnabled')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersioningEnabled:\s+FALSE/
  end,
  
  v(ZMProv.new('mc', name, 'zimbraFileVersionLifetime', '1m')) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('gc', name, 'zimbraFileVersionLifetime')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1] =~ /zimbraFileVersionLifetime:\s+1m/
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