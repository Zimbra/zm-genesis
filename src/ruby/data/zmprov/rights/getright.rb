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
#  Test case for getRight(gr) command

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/verify"
require "action/zmprov"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for getRight(gr) command"

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  # Basic grr
  v(ZMProv.new('gr','accessGAL')) do |mcaller, data|
   mcaller.pass = data[0] == 0 && data[1].include?('description: access GAL(global address list)')
  end,

 # getRight instead of gr
  v(ZMProv.new('getRight')) do |mcaller, data|
   mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,

  v(ZMProv.new('gr')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?('usage')
  end,

  #Bug:58077
  v(ZMProv.new('gr', 'accessGAL', '-e')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('description: access GAL(global address list)')
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