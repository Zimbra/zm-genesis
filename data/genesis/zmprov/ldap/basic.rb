#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
# zmprov -l basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/zmprov"
require "action/zmlocalconfig"
require "action/verify"
#require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov -l Basic test"

 
include Action

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
mLdapUrl = ZMLocalconfig.new('ldap_url').run[1][/=\s+(.*)/, 1]
 
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [
  v(cb("set ldap_url") do
    ZMLocalconfig.new('-e', "ldap_url=ldap://test.me:389").run
  end) do |mcaller, data|
   mcaller.pass = data[0] == 0
  end,

	#Get All Servers from ldap
	v(ZMProv.new('-l', 'gas', '2>&1')) do |mcaller, data|
	 mcaller.pass = data[0] != 0 && data[1].include?('FATAL: failed to initialize LDAP client')
	end,

	#Get All Servers from master ldap
	v(ZMProv.new('-m', '-l', 'gas')) do |mcaller, data|
	 mcaller.pass = data[0] == 0
	end,

]
#
# Tear Down
#
current.teardown = [
  ZMLocalconfig.new('-e', "ldap_url=\"#{mLdapUrl}\"")
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, true).run  
end