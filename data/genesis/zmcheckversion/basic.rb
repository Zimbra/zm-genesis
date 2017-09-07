#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# Test zmcheckversion
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
require "model"
require "action/zmcheckversion"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmcheckversion"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMCheckversion.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 1 && data[1].include?("usage: zmcheckversion <options>")\
                        &&	data[1].include?("-m,--manual   Initiate version check request.")\
                        &&	data[1].include?("-r,--result   Show results of last version check."))
  end,
  
  v(ZMCheckversion.new('-m')) do |mcaller,data|
	mcaller.pass = (data[0] == 0)
  end,
  
  v(ZMCheckversion.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 1 && !data[1].include?("INVALID_REQUEST"))
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
