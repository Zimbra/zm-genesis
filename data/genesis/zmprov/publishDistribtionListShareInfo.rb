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
#  Test case for zmprov command pdlsi(publishedDistributionListShareInfo)

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
current.description = "Test case for command pdlsi (publishedDistributionListShareInfo)"

name = 'zmprov'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
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

  # gpdlsi with invalid address
  v(ZMProv.new('pdlsi', 'onlyfoo')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
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