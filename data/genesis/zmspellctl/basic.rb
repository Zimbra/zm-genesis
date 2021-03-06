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
# Test zmspellctl star, stop, reload
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
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmspellctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMSpellctl.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("/opt/zimbra/bin/zmspellctl start|stop|restart|reload|status")
  end,

 v(ZMSpellctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?("already running")
  end,

  v(ZMSpellctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 1)&& data[1].include?("zmapachectl is not running")
  end,

  v(ZMSpellctl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?("Reloading apache")
  end,

  v(ZMSpellctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSpellctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
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