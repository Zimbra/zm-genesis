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
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov server Basic test"

 
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
	
	#Get All Server
	v(ZMProv.new('gas')) do |mcaller, data|	  
	 mcaller.pass = data[0] == 0 && data[1].include?(name)
	end,
	
	#Get Server
	v(ZMProv.new('gs', name)) do |mcaller, data|	
	 mcaller.pass = data[0] == 0 && data[1].include?('zimbraAdminPort') 
	end,
	
	#Modify Server
	v(ZMProv.new('ms', name, 'cn', name)) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,
	
	#Delete Server
	v(ZMProv.new('ds',name)) do |mcaller, data|	
	 mcaller.pass = data[0] == 0  
	end, 	   
  
  #Delete Server that is not empty. Bug #32709
  v(ZMProv.new('ds', Model::Servers.getServersRunning("mailbox").first)) do |mcaller, data| 
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: service.INVALID_REQUEST')  
  end,     
   
  # Get All MTA Auth URLs
    v(ZMProv.new('gamau')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].include?(Model::TARGETHOST.name)
  end,
  
  #getAllReverseProxyURLs(garpu) 
  # Currently this test is for No Proxy Setup. Need to upgrade for proxy setup later.
   v(ZMProv.new('garpu')) do |mcaller, data| 
   mcaller.pass = data[0] == 0 && data[1].include?(':7072/service/extension/nginx-lookup')
   end,

  #getAllMemcachedServers(gamcs) 
  # Currently this test is for No Proxy Setup. Need to upgrade for proxy setup later.
   v(ZMProv.new('gamcs')) do |mcaller, data| 
   mcaller.pass = data[0] == 0 
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