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
# Test zmthrdump
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
require "action/zmthrdump"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmthrdump"
defaultlogfile = '/opt/zimbra/log/zmmailboxd.out'
outfile = '/tmp/zmthrdump.out'
logfile = '/tmp/zmthrdump.log'
outfile = '/tmp/zmthrdump.out'
result = RunCommand.new('/bin/ps','zimbra', '-ef', '|', 'grep', '-i', 'mailboxd').run[1]
pid = result.match(/zimbra\s+(\d+)\s.*jetty\.xml/)[1]
timeout = 60

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  RunCommand.new('/bin/rm','zimbra','-f',logfile),
  RunCommand.new('/bin/rm','zimbra','-f',outfile),
  RunCommand.new('/bin/touch','zimbra',logfile),
  RunCommand.new('/bin/touch','zimbra',outfile),

  v(ZMThrdump.new) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('VM Periodic Task Thread')
  end,



  v(ZMThrdump.new('-p',pid)) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('VM Periodic Task Thread')
  end,

  v(ZMThrdump.new('-h')) do | mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Usage')
  end,

  v(ZMThrdump.new('-i')) do | mcaller, data|
    mcaller.pass = data[0] == 0
  end,


  v(ZMThrdump.new('-i','-t', timeout,'-p',pid,'-o',outfile)) do | mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMThrdump.new('-i','-p',pid,'-o',outfile)) do | mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMThrdump.new('-i','-p',pid,'-o',outfile)) do | mcaller, data|
     mcaller.pass = data[0] == 0
  end,

  v(ZMThrdump.new('-p','12345')) do | mcaller, data|
    mcaller.pass = data[0] == 1
  end,

  v(ZMThrdump.new('-f','/tmp/wrongfilename')) do | mcaller, data|
    mcaller.pass = data[0] == 1
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