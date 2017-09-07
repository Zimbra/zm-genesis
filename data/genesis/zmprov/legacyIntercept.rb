#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# 
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/block"
require "action/soap/login"
require "action/verify"
require "action/zmsoap"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zimbraInterceptAddress"


include Action

name = 'zmlegacy'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccountOne = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

#Start bug: 57114
  v(ZMProv.new('ca', testAccountOne.name, testAccountOne.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('ma', testAccountOne.name, 'zimbraInterceptSendHeadersOnly', 'TRUE')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  v(ZMProv.new('ma', testAccountOne.name, 'zimbraInterceptAddress', testAccountTwo.name)) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  v(ZMSoap.new('-m', testAccountOne.name ,'-p', 'test123', '-type', 'mail', '-f','/tmp/html-message.txt')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('SendMsgResponse') && !data[1].include?('service.FAILURE')
  end,
# End bug: 57114  

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
