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
# Test zmstatctl star, stop, reload
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
require "action/zmtrainsa"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmtrainsa"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMTrainsa.new) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting spam/ham extraction from system accounts')
  end,

  v(ZMTrainsa.new('-bad')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage: /opt/zimbra/bin/zmtrainsa')
  end,

  v(ZMTrainsa.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage: /opt/zimbra/bin/zmtrainsa')
  end,

  v(ZMTrainsa.new('--help')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage: /opt/zimbra/bin/zmtrainsa')
  end,

  v(ZMTrainsa.new("admin@#{Model::TARGETHOST}", 'ham', '/Inbox')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting spamassassin ham training for')
  end,

  # test to verify http://bugzilla.zimbra.com/show_bug.cgi?id=10083
  v(ZMTrainsa.new("admin@#{Model::TARGETHOST}", 'ham', '/Inbox')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) \
                   && data[1].include?('Starting spamassassin ham training for')\
                   && !data[1].include?('could not find site rules directory
    ')
  end,

  v(ZMTrainsa.new("admin@#{Model::TARGETHOST}", 'spam', '/Junk')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting spamassassin spam training for')
  end,

  v(ZMTrainsa.new("admin1@#{Model::TARGETHOST}", 'spam', '/Junk')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('can not find account')
  end,

  v(ZMTrainsa.new("admin@#{Model::TARGETHOST}", 'spammm', '/Junk')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?('Usage')
  end,

# Bug 26167
#  v(ZMTrainsa.new("admin@#{Model::TARGETHOST}", 'spam', '/Junk2')) do |mcaller, data|
#    mcaller.pass = (data[0] == 1) && data[1].include?('Starting spamassassin spam training for')
#  end,

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