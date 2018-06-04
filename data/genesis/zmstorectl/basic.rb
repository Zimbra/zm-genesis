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
# Test zmstorectl star, stop, reload
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
current.description = "Test zmstorectl"

#
# Setup
#
current.setup = [
]

#
# Execution
#
current.action = [

  #bug 47735: confirms that start and status should not return anything, hence commenting
  v(ZMStorectl.new, 240) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("/opt/zimbra/bin/zmstorectl start|stop|restart|reload|status")
  end,

  v(ZMStorectl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && !(data[1].include?("mailboxd already running") && !data[1].include?("mysqld_safe already running with pid"))
  end,

  v(ZMStorectl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && !data[1].include?("mysqld_safe already running with pid")
  end,

  v(ZMStorectl.new('status'), 240) do |mcaller, data|
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
