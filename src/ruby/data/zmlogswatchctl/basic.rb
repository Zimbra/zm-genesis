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
# Test zmlogswatchctl star, stop, restart
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

hasLogger = (ZMProv.new('gs',  Model::TARGETHOST.to_s, 'zimbraServiceEnabled').run)[1].split.any? {|x| x.include?('logger') } rescue false


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmlogswatchctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
if(hasLogger)
  current.action = [

                    ZMLogswatchctl.new('start'),

                    v(ZMLogswatchctl.new('start')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Starting logswatch...logswatch is already running.')
                    end,

                    v(ZMLogswatchctl.new('status')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('zmlogswatch is running.')
                    end,

                    v(ZMLogswatchctl.new('stop')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...done.')
                    end,

                    v(ZMLogswatchctl.new('status')) do |mcaller, data|
                      mcaller.pass = (data[0] == 1)&& data[1].include?('zmlogswatch is not running.')
                    end,

                    v(ZMLogswatchctl.new('stop')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...logswatch is not running.')
                    end,

                    v(ZMLogswatchctl.new('start')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Starting logswatch...done.')
                    end,

                    v(ZMLogswatchctl.new('restart')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...done.')\
                      && data[1].include?('Starting logswatch...done.')
                    end,

                    v(ZMLogswatchctl.new('reload')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...done.')\
                      && data[1].include?('Starting logswatch...done.')
                    end,



                    v(ZMLogswatchctl.new('status')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('zmlogswatch is running.')
                    end,

                    v(ZMLogswatchctl.new('stop')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...done.')
                    end,
                    # Bug
                    v(ZMLogswatchctl.new('reload')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Stopping logswatch...logswatch is not running.')\
                      && data[1].include?('Starting logswatch...done.')
                    end,

                    v(ZMLogswatchctl.new('start')) do |mcaller, data|
                      mcaller.pass = (data[0] == 0)&& data[1].include?('Starting logswatch...logswatch is already running.')
                    end,

                   ]
else
  current.action = []
end

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
