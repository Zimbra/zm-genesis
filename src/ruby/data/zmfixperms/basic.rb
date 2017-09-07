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
# Test zmfixperms
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
require "action/zmfixperms"
require "action/zmcontrol"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmfixperms"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMFixperms.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("/opt/zimbra/libexec/zmfixperms [-help] [-extended] [-verbose]")\
								 &&	data[1].include?("-help     Usage")\
								 &&	data[1].include?("-verbose  Verbose output")\
								 &&	data[1].include?("-extended Extended fix, includes store,index,backup directories"))
  end,

# Start bug 57891
  v(ZMFixperms.new('-extended')) do |mcaller,data|
  mcaller.pass = data[0] == 0 
  end,

  v(ZMControl.new('restart'))do | mcaller,data|
   mcaller.pass = data[0] == 0 && !data[1].include?('failed') && !data[1].include?('Stopped')
  end,
# End bug 57891



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
