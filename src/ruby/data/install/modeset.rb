#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare, Inc.
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model"
require "action/block"
require "action/runcommand"
require "action/zmprov"
require "action/verify"
require "action/zmamavisd"
require "action/zmproxyconfig"
require "#{mypath}/install/configparser"
require "action/zmcontrol"
require "#{mypath}/install/utils"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Settings needed for qa testing"

include Action


(mCfg = ConfigParser.new).run

 
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  # upgrades from 7.x - set mail mode to https
  if Utils::isUpgradeFrom('7\.\d+\.\d+')
  [
    mCfg.getServersRunning('proxy').map do |x|
      v(ZMProxyconfig.new("-e -w -x https -H #{x}", Model::Host.new(x))) do |mcaller, data|
        mcaller.pass = data[0] == 0
      end
    end,
    
    if mCfg.getServersRunning('proxy').empty?
    [
      mCfg.getServersRunning('store').map do |x|
      [
        v(ZMProv.new('gs', x, 'zimbraMailMode')) do | mcaller,data|
           mcaller.pass = data[0] == 0 && data[1] =~ /zimbraMailMode:\s+http$/
        end,
        if ZMProv.new('gs', x, 'zimbraMailMode').run[1] =~ /zimbraMailMode:\s+http$/
        [
          v(cb("mail mode setup") do
            mResult = ZMTlsctl.new('https', Model::Host.new(x)).run
            ZMProv.new('gs', x, 'zimbraMailMode').run
          end) do |mcaller, data|
            mcaller.pass = data[0] == 0 && data[1] =~ /zimbraMailMode:\s+https/
          end,
          v(ZMMailboxdctl.new('restart', Model::Host.new(x))) do | mcaller,data|
            mcaller.pass = data[0] == 0 && !data[1].include?('failed')
          end,    
          ZMMailboxdctl.waitForMailboxd(Model::Host.new(x)),
        ]
      end
      ]end,
    ]end,
    mCfg.getServersRunning('proxy').map do |x|
      v(ZMProxyctl.new('restart', Model::Host.new(x))) do |mcaller, data|
        mcaller.pass = data[0] == 0
      end
    end,
  ]end,
  
  # 8.5.0 - temporary workaround for soap smoke
  if true #ZMControl.new('-v').run[1] =~ /8\.5\.0\.GA/
    [
      mCfg.getServersRunning('*').map do |x|
      [
        v(ZMLocalconfig.new('-e', 'allow_unauthed_ping=true', h = Model::Host.new(x))) do | mcaller,data|
           mcaller.pass = data[0] == 0
        end,
          
        v(ZMMailboxdctl.new('restart', h)) do | mcaller,data|
          mcaller.pass = data[0] == 0 && !data[1].include?('failed')
        end,
      ]end
    ]end,
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