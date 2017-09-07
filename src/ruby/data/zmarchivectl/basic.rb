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

#
# Test basic zmarchivectl command
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
current.description = "Test zmarchivectl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMArchivectl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Starting zmmtaconfig...done.") || data[1].include?("Starting zmmtaconfig...zmmtaconfig is already running")\
                                  || data[1].include?("Starting amavisd...done.") || data[1].include?("Starting amavisd...amavisd is already running.")
  end,

  v(ZMArchivectl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('amavisd is running.')
  end,

  v(ZMArchivectl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.') 
  end,

  v(ZMArchivectl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Starting amavisd...done.") 
  end,

  v(ZMArchivectl.new('start'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Starting amavisd...amavisd is already running.")
  end,

  v(ZMArchivectl.new('reload'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Stopping amavisd... done.")&& data[1].include?("Starting amavisd...done.")
  end,

  v(ZMArchivectl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd... done.') 
  end,

  v(ZMArchivectl.new('stop')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping amavisd...amavisd is not running.')
  end,

  v(ZMArchivectl.new('restart'), 240) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Stopping amavisd...amavisd is not running.")&& data[1].include?("Starting amavisd...done.")
  end,

  v(ZMArchivectl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('amavisd is running.')
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
