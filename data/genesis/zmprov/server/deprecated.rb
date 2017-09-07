#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Vmware
#
# zmprov server basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/zmprov" 
require "action/verify"
#require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov server deprecated test"

 
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
	#Create Server
	v(ZMProv.new('cs',name)) do |mcaller, data|	
	 mcaller.pass = data[0] == 0
	end,
	
	#Modify Server
	v(ZMProv.new('ms', name, 'zimbraHsmAge', 23)) do |mcaller, data|
	 mcaller.pass = data[0] == 0 && data[1].include?('zimbraHsmAge has been deprecated')
	end,
                  
        #Get Server
	v(ZMProv.new('gs', name)) do |mcaller, data|	
	 mcaller.pass = data[0] == 0 && data[1].include?('zimbraHsmAge') 
	end,
	
	#Delete Server
	v(ZMProv.new('ds',name)) do |mcaller, data|	
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
