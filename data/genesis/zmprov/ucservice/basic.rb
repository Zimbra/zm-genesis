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
# zmprov UC service basic test

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
require "action/verify"
#require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov UC Service Basic test"

 
include Action

#name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
timeNow = Time.now.to_i.to_s
serviceOne = name + 'service' + '1' + timeNow
serviceTwo = name + 'service' + '2' + timeNow
serviceThree = name + 'service' + '3' + timeNow
providerOne = name + 'provider' + '1' + timeNow
accountOne = Model::TARGETHOST.cUser(name + '2' + timeNow, Model::DEFAULTPASSWORD)
accountTwo = Model::TARGETHOST.cUser(name + '3' + timeNow, Model::DEFAULTPASSWORD)
providerBackup = ZMProv.new('gcf', 'zimbraUCProviderEnabled').run[1][/zimbraUCProviderEnabled:\s+(\S+)$/, 1]
(ucAttrs = ZMProv.new('desc', "ucService").run[1].split(/\n/).select {|w| w =~ /^zimbraUC/}).delete('zimbraUCProvider')
 
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
                   data[1] =~ /zmprov help ucservice\s+help on ucservice-related commands/
                   (twoLines = data[1].split(/\n/).select {|w| w =~ /zmprov help (account|ucservice)/}).length == 2 &&
                   twoLines.first.index('zmprov help') == twoLines.last.index('zmprov help') &&
                   twoLines.first.index('help on account') == twoLines.last.index('help on ucservice')
  end,
  
  v(ZMProv.new('help', 'ucservice')) do |mcaller, data|
    usage = [Regexp.escape('createUCService(cucs) {name} [attr1 value1 [attr2 value2...]]'),
             Regexp.escape('deleteUCService(ducs) {name|id}'),
             Regexp.escape('getAllUCServices(gaucs) [-v]'),
             Regexp.escape('getUCService(gucs) [-e] {name|id} [attr1 [attr2...]]'),
             Regexp.escape('modifyUCService(mucs) {name|id} [attr1 value1 [attr2 value2...]]'),
             Regexp.escape('renameUCService(rucs) {name|id} {newName}')
            ]
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,
  
  # delete provider enabled 
  if !providerBackup.nil?
  [
    v(ZMProv.new('mcf', 'zimbraUCProviderEnabled', "\"\"")) do |mcaller, data|  
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
  ]
  end,
  
  # Fail to Create Service
  v(ZMProv.new('cucs', "\"#{serviceOne}\"", 'zimbraUCProvider', 'foo')) do |mcaller, data|  
    mcaller.pass = data[0] != 0 && data[1] =~ /ERROR:.*invalid request: no zimbraUCProviderEnabled is configured on global config/
  end,
  
  v(ZMProv.new('mcf', 'zimbraUCProviderEnabled', "\"#{providerOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  #Create UC service with provider != enabled provider not allowed
  v(ZMProv.new('cucs', "\"#{serviceOne}\"", 'zimbraUCProvider', 'foo')) do |mcaller, data|  
    mcaller.pass = data[0] != 0 && data[1] =~ /ERROR:.*invalid request: UC provider foo is not allowed by zimbraUCProviderEnabled/
  end,
  
  #Create UC Service
  v(ZMProv.new('cucs', "\"#{serviceOne}\"", 'zimbraUCProvider', "\"#{providerOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  
  #Get All UC Services
  v(ZMProv.new('gaucs')) do |mcaller, data|   
    mcaller.pass = data[0] == 0 && data[1].include?(serviceOne)
  end,
  
  #Get UC Service
  v(ZMProv.new('gucs', "\"#{serviceOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /cn: #{Regexp.escape(serviceOne)}$/ &&
                   data[1] =~ /objectClass: zimbraUCService$/ &&
                   data[1] =~ /zimbraUCProvider: #{Regexp.escape(providerOne)}$/
  end,
	
  #Create UC Service error
  v(ZMProv.new('cucs', "\"#{serviceOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /ERROR:.*object class violation/
  end,
  
  #Modify UC Service
  v(ZMProv.new('mucs', "\"#{serviceOne}\"", 'cn', "\"#{serviceOne}\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  ucAttrs.dup.collect! do |y|
    v(ZMProv.new('mucs', "\"#{serviceOne}\"", y, "\"qaVal_#{y}\"")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end
  end,
  
  v(ZMProv.new('gucs', "\"#{serviceOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /zimbraUCPresenceURL:\s+#{Regexp.escape('qaVal_zimbraUCPresenceURL')}$/
  end,
  
  cb('create voice account') do
    mServiceId = ZMProv.new('cucs',"\"#{serviceOne}\"", 'zimbraUCProvider', "\"#{serviceOne}\"").run[1].split.last
    ZMProv.new('ca', "\"#{accountOne.name}\"", "\"#{accountOne.password}\"", 'zimbraUCServiceId', mServiceId).run
  end,
  
  v(ZMProv.new('ca', "\"#{accountTwo.name}\"", "\"#{accountTwo.password}\"",
               'zimbraUCUsername', "\"#{accountTwo.name}\"", 'zimbraUCPassword', "\"#{accountTwo.password}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /^[\da-f\-]{36}$/
  end,
  
  v(ZMProv.new('ga', "\"#{accountTwo.name}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1][/zimbraUCUsername:\s+(\S+)$/, 1] == accountTwo.name.to_s &&
                   data[1][/zimbraUCPassword:\s+(\S+)$/, 1] == "VALUE-BLOCKED"
  end,
  
  v(ZMProv.new('-l', 'ga', "\"#{accountTwo.name}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   data[1][/zimbraUCUsername:\s+(\S+)$/, 1] == accountTwo.name.to_s &&
                   data[1][/zimbraUCPassword:\s+(\S+)$/, 1] !~ /VALUE-BLOCKED/ &&
                   data[1][/zimbraUCPassword:\s+(\S+)$/, 1] !~ /#{accountTwo.password}/
  end,
  
  v(ZMProv.new('cucs', "\"#{serviceTwo}\"", 'zimbraUCProvider', "\"#{providerOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1] =~ /^[\da-f\-]{36}$/
  end,
  
  #RenameUCService
  v(ZMProv.new('rucs', "\"#{serviceTwo}\"", "\"#{serviceThree}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMProv.new('gaucs')) do |mcaller, data|   
    mcaller.pass = data[0] == 0 && data[1].include?(serviceThree) && !data[1].include?(serviceTwo)
  end,
  
  # TODO zmprov renameUCService name|id newName

  v(ZMProv.new('rucs', "\"#{serviceThree}\"", "\"#{serviceOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] != 0 && data[1] =~ /ERROR: account.UC_SERVICE_EXISTS/
  end,
  
  #Delete Service
  v(ZMProv.new('ducs', "\"#{serviceOne}\"")) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMProv.new('ducs', "\"#{serviceThree}\"")) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMProv.new('gucs', "\"#{serviceOne}\"")) do |mcaller, data|  
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /no such uc service:\s+#{Regexp.escape(serviceOne)}/
  end,
  
  v(ZMProv.new('mcf', 'zimbraUCProviderEnabled', providerBackup.nil? ? "\"\"" : "\"#{providerBackup}\"")) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && data[1].empty?
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