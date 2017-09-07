#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Zimbra
#
# Basic test for web reverse proxy
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
require "action/wget"
require 'action/zmproxyconfig'

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Basic test for web reverse proxy"
#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [
  if Model::TARGETHOST.proxy
    [
    v(ZMProxyconfig.new("-e -w -u -x http -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,

    v(ZMTlsctl.new('both')) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     data[1].include?("Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done") &&
                     data[1].include?("Setting ldap config zimbraMailMode both")
    end,
    v(ZMMailboxdctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    ZMMailboxdctl.waitForMailboxd(),
    
    verifyWget('http://' + Model::TARGETHOST),
    verifyWgetError('https://' + Model::TARGETHOST),
    
    v(ZMProxyconfig.new("-e -w -U -x https -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
      
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    verifyWget('https://' + Model::TARGETHOST),
    verifyWgetError('http://' + Model::TARGETHOST),

    v(ZMProxyconfig.new("-e -w -u -x mixed -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
      
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    verifyWget('https://' + Model::TARGETHOST),
    verifyWget('http://' + Model::TARGETHOST),

    v(ZMProxyconfig.new("-e -w -u -x both -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
      
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    verifyWget('https://' + Model::TARGETHOST),
    verifyWget('http://' + Model::TARGETHOST),
    
    v(ZMProxyconfig.new("-e -w -c -U -x redirect -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
      
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    verifyWget('https://' + Model::TARGETHOST),
    verifyWget('http://' + Model::TARGETHOST),
    verifyWgetError('https://' + Model::TARGETHOST + ':9071'),
    
    v(ZMProxyconfig.new("-e -w -x stuff -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] != 0 && data[1].include?("INVALID_ATTR_VALUE")
    end,
    
    # Admin Console Proxy test
    v(ZMProxyconfig.new("-e -w -C -x https -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
      
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
    
    verifyWget('https://' + Model::TARGETHOST + ':9071'),

    # reset to default
    v(ZMProxyconfig.new("-e -w -U -c -x https -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == ""
    end,
    
    v(ZMProxyctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,

    v(ZMTlsctl.new('https')) do |mcaller, data|
      mcaller.pass = (data[0] == 0) &&
                     data[1].include?("Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done") &&
                     data[1].include?("Setting ldap config zimbraMailMode https")
    end,
      
    v(ZMMailboxdctl.new('restart'))do | mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
      
    ZMMailboxdctl.waitForMailboxd(),
    ]
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

