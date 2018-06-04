#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo

#
#
# Test basic zmproxyctl command
#
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
current.description = "Test zmproxyctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  if(Model::TARGETHOST.proxy == true)
    [    
      v(ZMProxyctl.new('start')) do |mcaller, data|
        mcaller.pass = (data[0] == 0)
      end,

      v(ZMProxyctl.new('status')) do |mcaller, data|
        mcaller.pass = (data[0] == 0)
      end,
    ]
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