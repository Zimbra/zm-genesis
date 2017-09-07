#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware
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
require "uri"

require "action/block" 
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify" 
require "action/zmlocalconfig"
require "action/zmamavisd.rb"
require "action/zmproxyconfig.rb"
require "#{mypath}/install/utils"
require "action/wget"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zimbra URLs test"

include Action

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s 

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
zMode = ZMProv.new('gs', Utils::zimbraHostname, 'zimbraMailMode').run[1][/zimbraMailMode:\s+(\S+)/, 1]
pMode = ZMProv.new('gs', Utils::zimbraHostname, 'zimbraReverseProxyMailMode').run[1][/zimbraReverseProxyMailMode:\s+(\S+)/, 1]
interval = '60' #ZMLocal.new('zmmtaconfig_interval').run

#
# Setup
#
current.setup = [
  begin
    interval = ZMLocal.new('zmconfigd_interval').run
    ZMLocalconfig.new('-e', 'zmconfigd_interval=86400')
  end
]


#
# Execution
#
current.action = [
  CreateAccount.new(testAccount.name,testAccount.password),
  v(cb("Briefcase URL check") {
    mUri = Utils::getClientURIInfo
    response = Action::RunCommand.new('wget','root',
                                      '--no-proxy',
                                      '--no-check-certificate',
                                      '--user', testAccount.name,
                                      '--password', testAccount.password,
                                      '-O', '-',
                                      mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port] + '/home/' + testAccount.name + 
                                      '/Briefcase').run.collect {|w| w.instance_of?(String)? w.encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''}) : w}
    response
  }) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1][/0K \.+\s+/] != nil
  end,

  
  if Model::TARGETHOST.proxy
  [
    v(ZMProxyconfig.new("-e -w -x http -u -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    v(ZMProxyctl.new('restart'))do |mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
  ]
  end,
  
  v(ZMTlsctl.new('http')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) \
      && data[1].include?("Attempting to set ldap config zimbraMailMode http on host " + Model::TARGETHOST + "...done.") \
      && data[1].include?("Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done.")
  end,
  v(ZMMailboxdctl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  ZMMailboxdctl.waitForMailboxd(),
    
    
  verifyWget('http://' + Model::TARGETHOST),
  verifyWgetError('https://' + Model::TARGETHOST),

  if Model::TARGETHOST.proxy
  [
    v(ZMProxyconfig.new("-e -w -x https -U -H #{Model::TARGETHOST}")) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    v(ZMProxyctl.new('restart'))do |mcaller,data|
      mcaller.pass = data[0] == 0 && !data[1].include?('failed')
    end,
  ]
  end,
  
 v(ZMTlsctl.new('https')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) \
      && data[1].include?("Attempting to set ldap config zimbraMailMode https on host " + Model::TARGETHOST + "...done.") \
      && data[1].include?("Rewriting config files for cyrus-sasl, webxml, mailboxd, service, zimbraUI, and zimbraAdmin...done.")
  end,
  v(ZMMailboxdctl.new('restart'))do | mcaller,data|
    mcaller.pass = data[0] == 0 && !data[1].include?('failed')
  end,
  ZMMailboxdctl.waitForMailboxd(),
  
  verifyWget('https://' + Model::TARGETHOST),
  verifyWgetError('http://' + Model::TARGETHOST),
  
  v(cb("non authenticated access check") {
    mUri = Utils::getClientURIInfo
    mPath = File.join('zimlet', 'com_zimbra_email', 'img', 'calendar_icon.png')
    genHttpCheck(mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port] + '/' + mPath).run
  }) do |mcaller, data|
    mcaller.pass = data[0] == 0 && !data[1][/\d+ OK/].nil? && data[1][/Length:\s+(\d+)/, 1] != '0'
  end,
  
  v(cb("authenticated access check") {
    mUri = Utils::getClientURIInfo
    mPath = File.join('service', 'zimlet', 'com_zimbra_email', 'img', 'calendar_icon.png')
    genHttpCheck(mUri[:mode] + '://' + mUri[:target] + ':' + mUri[:port] + '/' + mPath).run
  }) do |mcaller, data|
    mcaller.pass = data[0] != 0 && !data[1][/401 no authtoken cookie/].nil? && !data[1][/Authorization failed/].nil?
  end,
  
]

#
# Tear Down
#
current.teardown = [
  DeleteAccount.new(testAccount.name),
  ZMLocalconfig.new('-e', "zmconfigd_interval=#{interval}"),
  ZMTlsctl.new(zMode),
  ZMMailboxdctl.new('restart'),
  ZMProxyconfig.new(pMode),
  ZMProxyconfig.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run  
end 
