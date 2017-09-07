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

  v(ZMApachectl.new('stop')) do |mcaller, data|
    sleep(10)  #timing issue..stop is sometimes not fast enough
    mcaller.pass = (data[0] == 0) && !data[1].include?("FAILED") && data[1].include?("Stopping apache...done.")
  end,

  v(ZMApachectl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && !data[1].include?("FAILED") && data[1].include?("Starting apache...done.")
  end,

  v(ZMApachectl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("already running")
  end,

  v(ZMApachectl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && !data[1].include?("FAILED") && data[1].include?("Reloading apache...done.")
  end,

  v(ZMApachectl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  v(ZMApachectl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,

  #bug 28366 (fixed)
  v(ZMApachectl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 1)&& data[1].include?("apache is not running.")
  end,

  v(ZMApachectl.new('start')) do |mcaller, data|
  mcaller.pass = (data[0] == 0)
  end,

  v(ZMApachectl.new('reload')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  
  # Adding tests for bug 10692 Verifying exact status of command. Poonam: removed duplicate testcases
  v(ZMApachectl.new('restart')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("FAILED") && data[1].include?("Stopping apache...done.") && data[1].include?("Stopping apache...done.")
  end,
  
  v(ZMApachectl.new('graceful')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("FAILED") && data[1].include?("Reloading apache...done.")
  end,
  
  v(ZMApachectl.new('status')) do |mcaller, data|
	mcaller.pass = data[0] == 0 && !data[1].include?("FAILED") && data[1].include?("apache is running.")
  end,
  # END Adding tests for bug 10692
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
