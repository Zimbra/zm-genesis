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
# zmslapcat basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmcontrol"
require "action/zmslapcat"
require 'tmpdir'
require 'net/ldap'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmslapcat Basic test"


include Action

mName = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
mDir = File.join(Dir::tmpdir, mName)

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  ['', '-h', '--help'].map do |x|
    v(ZMSlapcat.new(x)) do |mcaller, data|
      usage = ['USAGE: Exports LDAP databases',
               'Main database: zmslapcat <DIR>',
               'Config database: zmslapcat -c <DIR>',
               'Accesslog database: zmslapcat -a <DIR>'
               ].collect {|w| Regexp.escape(w)}
      mcaller.pass = data[0] != 0 &&
                     data[1].split(/\n/).delete_if{|w| w =~ /^\s*$/}.select {|w| w !~ /#{usage.join('|')}/}.empty?
    end
  end,
  
  v(ZMSlapcat.new(mDir)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  #TBD: on multinode we may want to specify the ldap host
  v(RunCommandOnLdap.new('ls', Command::ZIMBRAUSER, File.join(mDir, 'ldap.bak'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].chomp == File.join(mDir, 'ldap.bak')
  end,
  
  v(ZMSlapcat.new('-c', mDir)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(RunCommandOnLdap.new('ls', Command::ZIMBRAUSER, File.join(mDir, 'ldap-config.bak'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].chomp == File.join(mDir, 'ldap-config.bak')
  end,
  
  v(cb('ldap-config.bak content check') do
    mResult = RunCommandOnLdap.new('cat', 'root', File.join(mDir, 'ldap-config.bak')).run
    cfgLdap = Net::LDAP::Dataset.read_ldif(StringIO.new(mResult[1])).to_entries rescue nil
    next [1, false, true] if cfgLdap.nil?
    is = cfgLdap.collect {|w| w[:dn].first}.sort
    sb = ["cn=config", "cn=module{0},cn=config", "cn=schema,cn=config", "cn={0}core,cn=schema,cn=config",
          "cn={1}cosine,cn=schema,cn=config", "cn={2}inetorgperson,cn=schema,cn=config", "cn={3}dyngroup,cn=schema,cn=config",
          "cn={4}zimbra,cn=schema,cn=config", "cn={5}amavisd,cn=schema,cn=config", "cn={6}opendkim,cn=schema,cn=config",
          "olcDatabase={-1}frontend,cn=config", "olcDatabase={0}config,cn=config", "olcDatabase={1}monitor,cn=config",
          "olcDatabase={2}mdb,cn=config",
         ].sort
    [0, is, sb]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] & data[2] == data[2]
  end,
  
  if RunCommand.new('ls', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH, 'data', 'ldap', 'accesslog', 'db')).run[0] != 0
  [
    v(ZMSlapcat.new('-a', mDir)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
      
    v(RunCommandOnLdap.new(File.join(Command::ZIMBRAPATH, 'libexec', 'zmldapenablereplica'), Command::ZIMBRAUSER)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1]  =~ /Enabling sync provider on master\.{3}succeeded/
    end,
  ]
  end,

  v(ZMSlapcat.new('-a', mDir)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(RunCommandOnLdap.new('ls', Command::ZIMBRAUSER, File.join(mDir, 'ldap-accesslog.bak'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].chomp == File.join(mDir, 'ldap-accesslog.bak')
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
