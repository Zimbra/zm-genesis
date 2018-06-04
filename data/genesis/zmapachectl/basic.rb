#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 VMWare
#
#
# Test basic zmapachectl command
#
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
current.description = "Test zmapachectl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMApachectl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) 
  end,

  v(ZMApachectl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("already running")
  end,

  v(ZMApachectl.new('status')) do |mcaller, data|
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
