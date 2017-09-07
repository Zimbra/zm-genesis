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
# Test sa-learn basic functions
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
require "action/sa-learn"
require "model"



include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test sa-learn"
# Test to verify bug 19420

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(SALearn.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 64) && data[1].include?('Usage')
  end,

  v(SALearn.new('--dbpath', '/opt/zimbra/data/amavisd/.spamassassin', '--siteconfigpath', '/opt/zimbra/conf/spamassassin', '--force-expire', '--sync'))  do |mcaller, data|
      mcaller.pass = ((data[0] == 0) && (data[1].include?('synced databases from journal') || data[1].empty?))
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