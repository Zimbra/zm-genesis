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
# Test zmaccts zmamavisd star, stop, restart etc.
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
current.description = "zmaccts and zmamavisd"
nNow = Time.now.to_i.to_s
#nMount = File.join(Command::ZIMBRAPATH, 'zipbackup'+nNow)
numberOfUser = 1
nameString = 'zmaccts'+Time.now.to_i.to_s
#
# Setup
#
current.setup = [

#  #Create Accounts
   CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),
]
#
# Execution
#
current.action = [

  #Create Accounts
  CreateAccounts.new(nameString, Model::TARGETHOST, numberOfUser, Model::DEFAULTPASSWORD),

  #Send emails

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmaccts'),Command::ZIMBRAUSER)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?(nameString)
  end,

  v(ZMAmavisd.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?('Starting amavisd...amavisd is already running.') || data[1].include?('Starting amavisd...done.')
  end,

  v(ZMAmavisd.new('status')) do |mcaller, data|
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