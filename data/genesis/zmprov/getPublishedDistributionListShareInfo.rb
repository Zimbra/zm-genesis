#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
#
#  Test case for gpdlsi(getPublishedDistributionListShareInfo) command

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"
require "action/verify"
require "action/command"
require "action/runcommand"
require "action/zmprov"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for gpdlsi(getPublishedDistributionListShareInfo) command"
adminAccount = "admin@"+Model::DOMAIN.to_s
#
# Setup
#
current.setup = [
 

]
#
# Execution
#
current.action = [

 v(ZMProv.new('gpdlsi', adminAccount)) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_DISTRIBUTION_LIST')
  end,

  # getPublishedDistributionListShareInfo instead of gpdlsi
  v(ZMProv.new('getPublishedDistributionListShareInfo', 'foo@foo.com')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: account.NO_SUCH_DISTRIBUTION_LIST')
  end,

  # gpdlsi with invalid address
  v(ZMProv.new('gpdlsi', 'onlyfoo')) do |mcaller, data|
   mcaller.pass = data[0] == 2 && data[1].include?('ERROR: service.INVALID_REQUEST (invalid request: must be valid email address: onlyfoo)')
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