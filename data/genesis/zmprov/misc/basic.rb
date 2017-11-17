#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
# zmprov misc basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"
require "action/block"
require "action/ldap"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Misc Basic test"


include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  #Exit
  v(ZMProv.new('exit')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  v(ZMProv.new('quit')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #Help
  v(ZMProv.new('?')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Try')
  end,
  v(ZMProv.new('help')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Try')
  end,
  
  v(ZMProv.new('help', 'misc')) do |mcaller, data|
       mcaller.pass = data[0] == 0 && data[1].include?("countObjects")
  end,

  #MaiboxInfo
  v(ZMProv.new('gmi',adminAccount)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('mailboxId')
  end,

  #Get Quota Usage
  v(ZMProv.new('gqu', Model::Servers.getServersRunning("mailbox").first)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(adminAccount.name)
  end,

  v(ZMProv.new('cd',name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Domain Pre Auth Key
  v(ZMProv.new('gdpak',name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('preAuth')
  end,

  # Domain Pre Auth
  v(ZMProv.new('gdpa',name,'test','id','0','0' )) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('preauth')
  end,

  v(ZMProv.new('dd',name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #Sync GAL
  v(ZMProv.new('syg', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(adminAccount.name)
  end,

  #addAccoutLogger
  v(ZMProv.new('aal', adminAccount.name, 'zimbra.ldap','debug')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  #getAccountLoggers
  v(ZMProv.new('gal', adminAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('zimbra.ldap=debug')
  end,

  #getAllAccountLoggers
  v(ZMProv.new('gaal', Model::TARGETHOST.to_s)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('zimbra.ldap=debug')
  end,

  #removeAccountLoggers
  v(ZMProv.new('ral', adminAccount.name, 'zimbra.ldap')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('rim')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?("usage:  reIndexMailbox(rim) {name@domain|id} {start|status|cancel} [{types|ids} {type or id} [,type or id...]]") &&
                   data[1].include?("Valid types:") &&
                   data[1].include?("appointment") &&
                   data[1].include?("contact") &&
                   data[1].include?("conversation") &&
                   data[1].include?("document") &&
                   data[1].include?("message") &&
                   data[1].include?("note") &&
                   data[1].include?("task")
  end,
  
  v(cb("always getting help")do
    Ldap.new('stop').run
    sleep(5)
    mResult = ZMProv.new('help').run
    Ldap.new('start').run
    sleep(10)
    mResult
  end)do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('Try')
  end,

  v(ZMProv.new('updatePresenceSessionId')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1] =~ /#{Regexp.escape('usage:  updatePresenceSessionId(upsid) {UC service name or id} ' +
                                                               '{app-username} {app-password}')}/
  end,

  v(ZMProv.new('upsid')) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1] =~ /#{Regexp.escape('usage:  updatePresenceSessionId(upsid) {UC service name or id} ' +
                                                               '{app-username} {app-password}')}/
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
  Engine::Simple.new(Model::TestCase.instance, true).run
end