#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/zmmailbox"
require "action/zmamavisd"
require "action/zmproxypurge"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
#require "net/pop"; require "action/pop"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP/POP login with default domain"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s + "_1"
defaultDomain = ZMProv.new('gcf', 'zimbraDefaultDomainName').run[1][/zimbraDefaultDomainName: (.*)$/, 1]
domain2 = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s + "x2" + ".org"
domain3 = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s + "x3" + ".org"

include Action
#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
]

#
# Execution
#
current.action = [
  ZMProv.new('cd', domain2.to_s),
  ZMProv.new('cd', domain3.to_s),  
  CreateAccount.new(name + '@' + defaultDomain.to_s, Model::DEFAULTPASSWORD),
  CreateAccount.new(name + '@' + domain2.to_s, Model::DEFAULTPASSWORD),
  CreateAccount.new(name + '@' + domain3.to_s, Model::DEFAULTPASSWORD),
  ZMailAdmin.new('-m', name + '@' + defaultDomain.to_s, 'createFolder', '/' + defaultDomain.to_s),
  ZMailAdmin.new('-m', name + '@' + domain2.to_s, 'createFolder', '/' + domain2.to_s),
  ZMailAdmin.new('-m', name + '@' + domain3.to_s, 'createFolder', '/' + domain3.to_s),

  # case 1 - default domain is set
  
  v(cb("login with full name") do
    mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mTemp.login(name + '@' + domain3.to_s, Model::DEFAULTPASSWORD)
    mResult = mTemp.list('', domain3.to_s)
    mTemp.logout
    mTemp.disconnect
    mResult
  end) do |mcaller, data|
    mcaller.pass = data.is_a?(Array) &&
                   data.first[:name] == domain3.to_s
  end,

  v(cb("login with short name") do
    mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mTemp.login(name, Model::DEFAULTPASSWORD)
    mResult = mTemp.list('', defaultDomain.to_s)
    mTemp.logout
    mTemp.disconnect
    mResult
  end) do |mcaller, data|
    mcaller.pass = data.is_a?(Array) &&
                   data.first[:name] == defaultDomain.to_s
  end,
  
  # case 2 - default domain is not set  
  
  ZMProxyPurge.new('-a', name + '@' + defaultDomain.to_s),
  ZMProv.new('mcf', 'zimbraDefaultDomainName', '""'),
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
  
  v(cb("login with full name") do
    mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mTemp.login(name + '@' + domain2.to_s, Model::DEFAULTPASSWORD)
    mResult = mTemp.list('', domain2.to_s)
    mTemp.logout
    mTemp.disconnect
    mResult
  end) do |mcaller, data|
    mcaller.pass = data.is_a?(Array) &&
                   data.first[:name] == domain2.to_s
  end,
  
  v(cb("login with short name") do
    mTemp = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
    mTemp.login(name, Model::DEFAULTPASSWORD)
    mResult = mTemp.list('', defaultDomain.to_s)
    mTemp.logout
    mTemp.disconnect
    mResult
  end) do |mcaller, data|
    mcaller.pass = data.class == Net::IMAP::NoResponseError &&
                   data.message == 'LOGIN failed'
  end
]

#
# Tear Down
#
current.teardown = [
  DeleteAccount.new(name + '@' + defaultDomain.to_s),
  DeleteAccount.new(name + '@' + domain2.to_s),
  DeleteAccount.new(name + '@' + domain3.to_s),
  ZMProv.new('dd', domain2.to_s),
  ZMProv.new('dd', domain3.to_s),  
  ZMProv.new('mcf', 'zimbraDefaultDomainName', defaultDomain.to_s)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
