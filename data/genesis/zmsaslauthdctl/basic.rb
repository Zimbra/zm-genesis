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
# Test zmsaslauthdctl star, stop, reload
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
current.description = "Test zmsaslauthdctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMSaslauthdctl.new) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("Usage: /opt/zimbra/bin/zmsaslauthdctl start|stop|kill|restart|reload|status")
  end,

  v(ZMSaslauthdctl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMSaslauthdctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('saslauthd is running')
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
