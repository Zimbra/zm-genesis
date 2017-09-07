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
#  Test case for getAllRights(gar) command

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
current.description = "Test case for getAllRights(gar) command"

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  v(ZMProv.new('help','right')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('getAllRights(gar) [-v] [-t {target-type}] [-c ALL|ADMIN|USER]')
  end,

  v(ZMProv.new('gar')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('getAllRights')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gar','-t','account','-c','ALL','|','wc','-l')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('ERROR')
  end,

  v(ZMProv.new('gar','-t','account','-c','ADMIN','|','wc','-l')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('ERROR')
  end,

  v(ZMProv.new('gar','-t','account','-c','USER','|','wc','-l')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1].include?('ERROR')
  end,

  v(ZMProv.new('gar','-v','-t','account','-c','ALL')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gar','-v','-t','account','-c','ADMIN')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gar','-v','-t','account','-c','USER')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Invalid option
  v(ZMProv.new('gar','l')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && !data[1].include?('ERROR')
  end,

  v(ZMProv.new('gar','-v','-t','account','-c','admin')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('ERROR: service.INVALID_REQUEST (invalid request: unknown right class: admin)')
  end,
  # END Invalid option

  #Bug:68391
  v(ZMProv.new('gar', 'l')) do |mcaller, data|
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