#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Test zmsoap basic functions
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "action/zmsoap"
require 'action/zmcontrol'
require "model"
require 'json'


include Action
adminAccount = 'admin@'+Model::TARGETHOST.to_s
nNow = Time.now.to_i.to_s
#
current = Model::TestCase.instance()
current.description = "Test zmsoap"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  RunCommand.new('/bin/echo','root','test123', '>','/tmp/passfile'),

  ['h', '-help'].map do |x|
    v(ZMSoap.new('-' + x)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?('usage: zmsoap [options]')
    end
  end,

  v(ZMSoap.new('-z', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,
  
  v(ZMSoap.new('-m', adminAccount, '-p', Model::DEFAULTPASSWORD, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a',adminAccount,'-p', 'test123', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a',adminAccount,'-P', '/tmp/passfile', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse')
  end,

  v(ZMSoap.new('-a',adminAccount,'-t', 'account', '-P', '/tmp/passfile', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('unknown document: SearchRequest')
  end,

  v(ZMSoap.new('-a',adminAccount,'-v', '-P', '/tmp/passfile', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchRequest xmlns="urn:zimbraMail"')
  end,

  v(ZMSoap.new('-a',adminAccount,'-u','https://wronghost:7071/service/admin/soap', '-P', '/tmp/passfile', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    puts "data: #{data}"
    mcaller.pass = data[0] == 0 && data[1].include?('java.net.UnknownHostException: wronghost')
  end,

  v(ZMSoap.new('-a',adminAccount,'-n', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('</SearchRequest>')
  end,

  v(ZMSoapXml.new('-v', '-z', '-m', adminAccount, '-t', 'mobile', 'GetDeviceStatusRequest')) do |mcaller, data|
    isNetwork = ZMControl.new('-v').run[1] =~ /NETWORK/
    mcaller.pass = isNetwork && data[0] == 0 && data[1].elements.size == 1 && !data[1].elements['GetDeviceStatusResponse'].nil? ||
                   !isNetwork && data[0] != 0
  end,
    
  RunCommand.new('/bin/echo', 'root', "\"{\\\"SearchRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraMail\\\", \\\"query\\\":\\\"in:inbox\\\"}}\"", '>','/tmp/jsonfile'),
    
  v(ZMSoap.new('-z', '-m', adminAccount, '--json', '-f', '/tmp/jsonfile')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["sortBy", "offset", "c", "more", "_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraMail'
  end,
    
  RunCommand.new('/bin/echo', 'root', "\"{\\\"GetDeviceStatusRequest\\\":{\\\"_jsns\\\":\\\"urn:zimbraSync\\\"}}\"", '>','/tmp/jsonfile'),

  v(ZMSoap.new('-z', '-m', adminAccount, '-t', 'mobile', '--json', '-f', '/tmp/jsonfile')) do |mcaller, data|
    isNetwork = ZMControl.new('-v').run[1] =~ /NETWORK/
    mcaller.pass = isNetwork && data[0] == 0 && !(response = JSON.parse(data[1]) rescue nil).nil? &&
                   response.keys.sort & (keys = ["_jsns"].sort) == keys &&
                   response['_jsns'] == 'urn:zimbraSync'  ||
                   !isNetwork && data[0] != 0
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