#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 VMWare, Inc.
#
# Test zmconfigdctl config changes detection
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
require "action/zmlocalconfig"
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmconfigdctl config changes detection"

restoreInterval = nil
ldapBackup = {}

def collectLdapConfig()
  # Digest::MD5.hexdigest(File.open('/tmp/xxx.txt') { |f| f.read})
  # on MAC : stat -f "%N | %t%Sm" /opt/zimbra/data/ldap/config/cn\=config/*
  # others : stat --format "%y | %n" /opt/zimbra/data/ldap/config/cn=config/*
  mResult = RunCommand.new('stat', 'root', '--format "%n | %y" /opt/zimbra/data/ldap/config/cn=config/*.ldif').run
  #puts mResult
  return mResult if mResult[0] != 0
  md5Cmd = (Model::TARGETHOST.architecture == 66 ? '/sbin/': '') + 'md5' +
           (Model::TARGETHOST.architecture == 9 || Model::TARGETHOST.architecture == 66 ? '' : 'sum')
  mFilter = ['^#', 'modifyTimestamp:', 'entryCSN:']
  mSedDelete = mFilter.collect {|w| "-e \"/#{w}/d\""}
  mCfg = {}
  mResult[1].split(/\n/).each do |w|
    tok = w.split(/\s+\|\s+/)
    mCfg[tok[0]] = {'modified' => tok[1], 'md5' => 'DEAD'}
  end
  mCfg.each_pair do |k, v|
    mResult = RunCommand.new('sed', 'root', mSedDelete, k, "|", md5Cmd).run
    mCfg[k]['md5'] = mResult[1].chomp.split().first if mResult[0] == 0
  end
  [0, mCfg]
end

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  #backup files as {file =>[date-stamp, md5checksum]}
  v(cb('backup ldap hdb files') do
    mResult = collectLdapConfig
    ldapBackup = mResult[1]
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].keys.select {|k| data[1][k].has_value?('DEAD')}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap config backup' => {"SB" => "exit code 0 - success", "IS" => "exit code #{data[0]}, #{data[1]}"}}
      if data[0] == 0
        mRes = {}
        data[1].each_pair do |k, v|
          mRes[k + ' checksum'] = {"IS" => v['md5'], "SB" => 'MD5 checksum'} if v.has_value?('DEAD')
        end
        mcaller.badones['ldap config backup'] = mRes
      end
    end
  end,

  ZMConfigdctl.new('restart'),
  
  #verify files are unchanged i.e. new date-stamp == old.date-stamp || new md5 != old md5
  v(cb('stop replacing duplicates in ldap config db') do
    collectLdapConfig
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].keys.sort == ldapBackup.keys.sort && 
                   data[1].keys.select {|k| data[1][k]['modified'] != ldapBackup[k]['modified'] && data[1][k]['md5'] == ldapBackup[k]['md5']}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'stop replacing duplicates in ldap config db' => {"SB" => ldapBackup, "IS" => data[1]}}
    end
  end,
 
  v(cb("multivalued test", 600) do
    mAttribute = 'zimbraSSLExcludeCipherSuites'
    mObject = ZMProv.new('gcf', mAttribute)
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    expected = mResult[1].split(/\n/).select {|w| w =~ /#{mAttribute}/}.collect {|w| w[/#{mAttribute}:\s+(.*)$/, 1]}
    #check/set zmmtaconfig_interval
    mResult = ZMLocal.new('zmmtaconfig_interval').run
    #assume it's not undefined for now
    if mResult != '60'
      restoreInterval = mResult
      mResult = ZMLocalconfig.new('-e', 'zmmtaconfig_interval=60').run
      mResult = ZMMtaconfigctl.new('restart').run
      sleep(60) + 20
    end
    mDetector = RunCommand.new('grep', 'root', mAttribute, File.join(Command::ZIMBRAPATH, 'log', 'zmconfigd.log'))
    preExisting = mDetector.run[1].split(/\n/)
    mObject = RunCommand.new('zmprov', Command::ZIMBRAUSER, 'mcf',
                             '-' + mAttribute, expected.first,
                             '; zmprov', 'mcf', '+' + mAttribute, expected.first)
    mResult = mObject.run
    sleep(60 + 20)
    found = mDetector.run[1].split(/\n/)
    if !restoreInterval.nil?
      mResult = ZMLocalconfig.new('-e', "zmmtaconfig_interval=#{restoreInterval}").run
      mResult = ZMMtaconfigctl.new('restart').run
    end
    [found - preExisting, expected]
  end) do |mcaller, data|
    mcaller.pass = data[0].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      #race condition?
      mValues = data[0].first[/->\s+'([^']+)/, 1].split(/\s+/)
      if mValues.sort == data[1].sort
        mcaller.badones = {"multivalue test" => {"IS" => data[0].first, "SB" => "Missing"}}
      else
        mcaller.badones = {"possible race condition or old build (bug 58361)" => {"IS" => mValues.sort.join(" "), "SB" => data[1].sort.join(" ")}}
      end
    end
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
