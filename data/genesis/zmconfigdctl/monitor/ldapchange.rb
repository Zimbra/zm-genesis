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
#require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmlocalconfig"
require "action/zmamavisd"
require 'net/ldap'


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmconfigdctl changes ldap"

restoreInterval = ZMLocal.new('zmconfigd_interval').run
currentValue = nil
ldapBackup = {}

refreshInterval = '20'

module DictionaryFactory
  def create(title)
    raise NotImplementedError, "You should implement this method"
  end
end

class LdapConfigFactory
  include DictionaryFactory
    #attr_accessor :entries
    #attr_accessor :tuples
  @@entries = {}
  @@tuples = {'ldap_common_loglevel' => 'olcLogLevel',
              'ldap_common_tlsprotocolmin' => 'olcTLSProtocolMin',
              'ldap_common_tlsciphersuite' => 'olcTLSCipherSuite',
              'ldap_db_maxsize' => 'olcDbMaxSize',
              'ldap_db_envflags' => 'olcDbEnvFlags'
             }
  attr :source
  def create(source)
    if !@@tuples.keys.include? source
      raise NotImplementedError, "You should implement this method"
    end
    if @@entries.empty? || !@@entries.keys.include?(LdapConfigEntry.new(source))
      if source == 'ldap_common_loglevel'
        @@entries[LocalLogLevel.new(source)] = LdapLogLevel.new(@@tuples[source])
      elsif source == 'ldap_common_tlsprotocolmin'
        @@entries[LocalTlsProtocolMin.new(source)] = LdapConfigEntry.new(@@tuples[source])
      elsif source == 'ldap_common_tlsciphersuite'
        @@entries[LocalTlsCipherSuite.new(source)] = LdapConfigEntry.new(@@tuples[source])
      elsif source == 'ldap_db_maxsize'
        @@entries[LocalDbMaxSize.new(source)] = LdapConfigEntry.new(@@tuples[source])
      elsif source == 'ldap_db_envflags'
        @@entries[LocalEnvFlags.new(source)] = LdapConfigEntry.new(@@tuples[source])
      else
        @@entries[LocalconfigEntry.new(source)] = LdapConfigEntry.new(@@tuples[source])
      end
    end
  end
  def LdapConfigFactory.entries()
    @@entries
  end
  def LdapConfigFactory.tuples()
    @@tuples
  end
end

class DictionaryEntry
  @source = nil
  def initialize(source)
    @source = source
  end
  
  def newValue(current)
    raise NotImplementedError, "You should implement this method"
  end
  
  def read()
    raise NotImplementedError, "You should implement this method"
  end
  def write(val)
    raise NotImplementedError, "You should implement this method"
  end
  def to_s()
    @source
  end
end

class LdapConfigEntry < DictionaryEntry
  
  def initialize(aname)
    @source = aname
    if !defined?(@@ldap)
      ldapUrl = ZMLocal.new('ldap_url').run.split(/\s+/)[-1]
      zimbraUser = ZMLocal.new('zimbra_ldap_userdn').run
      zimbraPassword = ZMLocal.new('zimbra_ldap_password').run
      rPassword = ZMLocal.new('ldap_root_password').run
      @@ldap = Net::LDAP.new(:host => ldapUrl[/ldaps?:\/\/([^:]+).*/, 1],
                            :port => ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1],
                            :auth => {:method => :simple,
                            :username => 'cn=config',
                            :password => rPassword},
                            :encryption => ldapUrl =~ /ldaps/ ? {:method => :simple_tls} : nil
                           )
  end
  end
  
  def read()
    mResult = @@ldap.search(:base => 'cn=config', #:base => '"olcDatabase={2}mdb,cn=config"',
                              :attributes => [@source],
                              :return_result => true,
                              :filter => Net::LDAP::Filter.eq(@source, "*")
                             )
    return [@@ldap.get_operation_result.code, mResult.first[@source].first]
  end
end

class LdapLogLevel < LdapConfigEntry
  def read()
    mResult = @@ldap.search(:base => 'cn=config', #:base => '"olcDatabase={2}mdb,cn=config"',
                              :attributes => [@source],
                              :return_result => true,
                              :filter => Net::LDAP::Filter.eq(@source, "*")
                             )
    return [@@ldap.get_operation_result.code, mResult.first[@source].first] if mResult.first[@source].first =~ /\d+/
    levels = {'None' => 32768, 'Sync' => 16384, 'Stats' => 256}
    res = 0
    mResult.first[@source].each {|w| res += levels[w]}
    [@@ldap.get_operation_result.code, res]
  end
end

class LocalconfigEntry < DictionaryEntry
  def read()
    mResult = ZMLocalconfig.new(@source).run
    [mResult[0], mResult[1][/#{@source}\s+=\s+(.*)/, 1]]
  end
  def write(val)
    ZMLocalconfig.new('-e', "#{@source}=\"#{val.to_s}\"").run
  end
end

class LocalLogLevel < LocalconfigEntry
  def newValue(current)
    if current == '49152'
      return '256'
    else
      return '49152'
    end
  end
end

class LocalTlsProtocolMin < LocalconfigEntry
  def newValue(current)
    if current == '3.1'
      return '3.2'
    else
      return '3.1'
    end
  end
end

#ldap_common_tlsciphersuite = MEDIUM:HIGH
class LocalTlsCipherSuite < LocalconfigEntry
  def newValue(current)
    if current == 'MEDIUM:HIGH'
      return 'LOW:MEDIUM:HIGH'
    else
      return 'MEDIUM:HIGH'
    end
  end
end

class LocalDbMaxSize < LocalconfigEntry
  def newValue(current)
    if current == '29784694784'
      return (29784694784 - 1024).to_s
    else
      return '29784694784'
    end
  end
end

#ldap_accesslog_envflags
class LocalEnvFlags < LocalconfigEntry
  def newValue(current)
    if current == 'writemap nometasync'
      return 'writemap'
    else
      return 'writemap nometasync'
    end
  end
end

myFactory = LdapConfigFactory.new
myFactory.create('ldap_common_loglevel')
myFactory.create('ldap_common_tlsprotocolmin')
myFactory.create('ldap_common_tlsciphersuite')
#myFactory.create('ldap_db_maxsize') ## needs ldap restart
#myFactory.create('ldap_db_envflags')
crtVal = nil
newVal = nil


#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  if restoreInterval != refreshInterval
  [
    v(ZMLocalconfig.new('-e', "zmconfigd_interval=#{refreshInterval}")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(ZMConfigdctl.new('restart')) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end
  ]
  end,

  LdapConfigFactory.entries.keys.map do |x|
  [  
    v(cb("read") do
      mResult = x.read
      crtVal = mResult[1]
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
    v(cb("write") do
      mResult = x.write((newVal = x.newValue(crtVal)))
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
    cb("Sleep") { Kernel.sleep(refreshInterval.to_i + 10)},

    v(cb("read target") do
      mResult = LdapConfigFactory.entries[x].read
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == newVal
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x.to_s => {"IS" => "#{data[1]}, exit code=#{data[0]}", "SB" => newVal}}
      end
    end,

    ###restore settings for testing only
    v(cb("write") do
      mResult = x.write(crtVal)
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
  ]
  end,

  v(ZMConfigdctl.new('restart')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end

]
#
# Tear Down
#

current.teardown = [
  if restoreInterval != refreshInterval
  [
    ZMLocalconfig.new('-e', "zmconfigd_interval=#{restoreInterval}"),
    ZMConfigdctl.new('restart')
  ]
  end
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
