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
# Test zmqaction
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmqaction"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmqaction"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [


  v(ZMQaction.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 1 && data[1].include?("Usage: zmqaction action queuename queuid1[,queueid2]+"))
                                                                                
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
