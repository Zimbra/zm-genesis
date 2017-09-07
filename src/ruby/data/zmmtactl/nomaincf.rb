#!/bin/env ruby
#
# $File: //depot/zimbra/main/ZimbraQA/data/genesis/zmmtactl/basic.rb $
# $DateTime: 2010/11/18 03:07:15 $
#
# $Revision: #9 $
# $Author: poonam $
#
# 2011 VMware
#
# Test zmmtactl with missing main.cf
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
current.description = "Test postfix with missing main.cf"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

                  v(ZMMtactl.new('stop')) do |mcaller, data|
                    mcaller.pass = (data[0] == 0) && data[1].include?('Stopping saslauthd...done.')
                  end,
                  
                  v(RunCommand.new('rm','root', File.join(Command::ZIMBRACOMMON, 'conf', 'main.cf'))) do |mcaller, data|
                    mcaller.pass = (data[0] == 0)
                  end,
                  
                  v(ZMMtactl.new('start'), 240) do |mcaller, data|
                    mcaller.pass = (data[0] == 0) && data[1].include?('Rewriting configuration files...done.')\
                    && data[1].include?('Starting saslauthd...done.')
                  end,

                  v(RunCommand.new('ls','root', '-l', File.join(Command::ZIMBRACOMMON, 'conf', 'main.cf'))) do |mcaller, data|
                    mcaller.pass = (data[0] == 0) && data[1].include?('root root')
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
