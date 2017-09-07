#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Zimbra
#
# Test zmtlsctl modes
# Should not be executed on configurations with Nginx
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
require "action/zmcontrol"
require "action/wget"

include Action

mMode = 'UNDEF'
mMsg = 'UNDEF'

#
# Global variable declaration
#

current = Model::TestCase.instance()
current.description = "Test zmtlsctl"
#
# Setup
#
current.setup = [

                ]
#
# Execution
#
current.action = [
  
  v(cb("Mode backup") do
    mResult = ZMProv.new('gs', Model::TARGETHOST, 'zimbraMailMode').run
    mMode = mResult[1][/zimbraMailMode:\s+(.*)/, 1]
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1]  =~ /zimbraMailMode:\s+/
  end,
  # For http, the command should exit with status 1 since we do not support http mode
  
  v(ZMTlsctl.new('http')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?("Error: When zimbraReverseProxyMailMode")
  end,
  
  #Mailboxd has to be stopped and restarted for the change to take effect
  v(ZMControl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  
  verifyWgetError('http://' + Model::TARGETHOST + (Model::TARGETHOST.proxy ? ':8080' : ':80')),
  
  #For https
  
  v(ZMTlsctl.new('https')) do |mcaller, data|
    mcaller.pass = data[0] == 0  && data[1].include?("Attempting to set ldap config zimbraMailMode https")
  end,
  
  #Mailboxd has to be stopped and restarted for the change to take effect
  v(ZMControl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  
  verifyWget('https://' + Model::TARGETHOST + (Model::TARGETHOST.proxy ? ':8443' : ':443')),
  verifyWgetError('http://' + Model::TARGETHOST + (Model::TARGETHOST.proxy ? ':8080' : ':80')),
  
  #For both
  
  v(ZMTlsctl.new('both')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Attempting to set ldap config zimbraMailMode both")
  end,
  
  v(ZMControl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  verifyWget('https://' + Model::TARGETHOST + (Model::TARGETHOST.proxy ? ':8443' : ':443')),	
  
  v(cb("Mode restore") do
    mResult = ZMTlsctl.new(mMode).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done.') &&
                   data[1].include?("Attempting to set ldap config zimbraMailMode #{mMode}")
  end,  
  
  #Mailboxd has to be stopped and restarted for the change to take effect
  v(ZMControl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
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
