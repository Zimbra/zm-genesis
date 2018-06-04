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
# Test zmswatchctl star, stop, reload
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
require "action/zmamavisd"
require "action/zmlocalconfig"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmswatchctl"

hasSnmp = (ZMProv.new('gs',  Model::TARGETHOST.to_s, 'zimbraServiceEnabled').run)[1].split.any? {|x| x.include?('snmp') } rescue false
  
name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccount1 = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
smtpDest = ZMLocal.new("smtp_destination").run

#
# Setup
#
current.setup = [


]
#
# Execution
#
if hasSnmp
  current.action = [

    v(ZMSwatchctl.new) do |mcaller, data|
      mcaller.pass = (data[0] == 1) && data[1].include?('/opt/zimbra/bin/zmswatchctl start|stop|restart|reload|status')
    end,

    v(ZMSwatchctl.new('start')) do |mcaller, data|
      mcaller.pass = (data[0] == 0)&& data[1].include?('Starting swatch...swatch is already running.')
    end,

    v(ZMSwatchctl.new('status')) do |mcaller, data|
      mcaller.pass = (data[0] == 0)&& data[1].include?('swatch is running.')
    end,

      
    v(ZMProv.new('CreateAccount', testAccount1.name, testAccount1.password)) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
      
    v(ZMLocalconfig.new('-e', "smtp_destination=#{testAccount1.name}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    # check conf/swatchrc
    # TODO: stop a service, check notification, start service
    v(RunCommand.new('grep', 'root',  "#{testAccount1.name}", '/opt/zimbra/conf/swatchrc')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] =~ /\b#{testAccount1.name}\b/
    end,
      
    v(ZMLocalconfig.new('-e', "smtp_destination=#{smtpDest}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
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
