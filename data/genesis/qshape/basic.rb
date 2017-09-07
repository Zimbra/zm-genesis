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
# Test qshape basic functions
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
require "action/qshape"
require "model"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test qshape"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(QShape.new('-h')) do |mcaller, data|
    mcaller.pass = data[1].include?('Usage')
  end,

#  v(QShape.new('--help')) do |mcaller, data|
#    mcaller.pass = (data[0] == 1) && data[1].include?('usage')
#        if !mcaller.pass
#      mcaller.message = "Bug33743 TM: GnR D2 Expect retcode == 1 and correct usage"
#    end
#  end,

 v(QShape.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('TOTAL')
  end,

 v(QShape.new('deferred')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('TOTAL')
  end,

 v(RunCommand.new(Command::ZIMBRAPATH+'/bin/qshape','root')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('qshape must be run as user zimbr')
    if !mcaller.pass
      mcaller.message = "Bug33743 TM: GnR D2 Expect retcode == 1"
    end
 end
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