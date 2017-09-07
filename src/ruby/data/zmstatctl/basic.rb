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

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"
require "#{mypath}/install/configparser"
require "action/buildparser"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmstatctl"

mStats = ['zmstat-io-x',
          'zmstat-io',
          'zmstat-cpu',
          'zmstat-vm',
          'zmstat-allprocs',
          'zmstat-df',
          'zmstat-mtaqueue',
          'zmstat-proc',
          'zmstat-fd',
          'zmstat-ldap',
          'zmstat-mysql',
          'zmstat-nginx',
          'zmstat-convertd'
         ]
(mCfg = ConfigParser.new).run
mStats.push('zmstat-convertd') if BuildParser.instance.targetBuildId =~ /NETWORK/i && mCfg.getServersRunning('convertd').include?(Model::TARGETHOST.to_s)
mStats.push('zmstat-nginx') if mCfg.getServersRunning('proxy').include?(Model::TARGETHOST.to_s)
#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  v(ZMStatctl.new) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?("Usage: zmstatctl start|stop|restart|status|rotate")
  end,

 v(ZMStatctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/(\S+)\s+already\s+running,\s+skipping\./, 1]}.sort == mStats.sort

  end,

 v(ZMStatctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/(\S+)\s+already\s+running,\s+skipping\./, 1]}.sort == mStats.sort

  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Running:\s+(\S+)/, 1]}.sort == mStats.sort
  end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Terminating\s+process\s+(\d+)/, 1]}.uniq.length == mStats.length
  end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 1
  end,

  v(ZMStatctl.new('start')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Invoking:\s+#{File.join(Command::ZIMBRAPATH, 'libexec')}#{File::SEPARATOR}(.*)$/, 1].gsub(/io\s+-x/, 'io-x')}.sort == mStats.sort
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  
  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Running:\s+(\S+)/, 1]}.sort == mStats.sort
 # Removing convertd as it is only on Network and only if convertd is present                                
  end,

  v(ZMStatctl.new('rotate')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Sending\s+HUP\s+to\s+process\s+(\S+)/, 1]}.uniq.length == mStats.length
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length &&
                   lines.collect {|w| w[/Running:\s+(\S+)/, 1]}.sort == mStats.sort 
   end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('rotate')) do |mcaller, data|
    mcaller.pass = data[0] == 1
  end,

  v(ZMStatctl.new('start', '; sleep 10')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('restart')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).length == mStats.length * 2 &&
                   (terminated = lines.collect {|w| w[/Terminating\s+process\s+\d+/]}.compact).uniq.length == mStats.length &&
                   (lines - terminated).collect {|w| w[/Invoking:\s+#{File.join(Command::ZIMBRAPATH, 'libexec')}#{File::SEPARATOR}(.*)$/, 1].gsub(/io\s+-x/, 'io-x')}.compact.sort == mStats.sort
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
