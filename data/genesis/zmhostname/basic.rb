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
# Test zmtlsctl star, stop, reload
#


#if($0 == __FILE__)
#  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
#end


if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmhostname"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

 v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmhostname'),Command::ZIMBRAUSER)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?(Model::TARGETHOST)
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