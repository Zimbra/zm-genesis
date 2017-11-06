#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test zmldapreplicatool
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmldapreplicatool"
require "action/zmlocalconfig"

include Action

require 'net/ldap'
ldapUrl = ZMLocal.new('ldap_url').run.split(/\s+/).first
zimbraPassword = ZMLocal.new('ldap_root_password').run
zimbraPassword = 'zimbra'
ldap = Net::LDAP.new(:host => ldapUrl[/ldaps?:\/\/([^:]+).*/, 1],
                     :port => ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1],
                     :auth => {:method => :simple,
                               :username => "cn=config",
                               :password => zimbraPassword},
                     :encryption => ldapUrl =~ /ldaps/ ? {:method => :simple_tls} : nil
                     )

def getReplicationConfig(netLdap)
  begin
    netLdap.bind
    cfg= netLdap.search(:base => 'olcDatabase={2}mdb,cn=config',
                        :filter => Net::LDAP::Filter.eq("olcSyncrepl", "*"),
                        :attributes => ['olcSyncrepl'],
                        :return_result => true)
    cfg[0].olcSyncrepl[0]
  rescue StandardError => e
    nil
  end
end

def getReplicas()
  replicas = nil
  ldaps = ZMProv.new('gas', 'ldap').run[1].split(/\n/)
  ldaps.each do |host|
    myHost = Model::Host.new(host.gsub(/\.#{Model::TestDomain}/, ''), Model::TestDomain)
    next if ZMLocal.new(myHost, 'ldap_is_master').run == 'true'
    replicas.push(myHost) rescue replicas = [myHost]
  end
  replicas
end

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmldapreplicatool"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'libexec', 'zmldapreplicatool'), 'root', '-h')) do |mcaller,data|
    expected = 'ERROR: must be run as zimbra user'
    mcaller.pass = data[0] != 0 && (data[1].include?(expected) ^ data[2].include?(expected))
  end,

  ['h', 'H', '-help'].map do |x|
    v(ZMLdapreplicatool.new('-' + x)) do |mcaller,data|
      mcaller.pass = data[0] != 0 && data[1].include?("zmldapreplicatool")
    end
  end,

  [ZMLocal.new('ldap_is_master').run].select {|w| w == 'false'}.map do |x|
  [
    v(cb('syncrepl rid test') do
      expected = rand(0-999) + 0
      mResult = ZMLdapreplicatool.new('-r', expected).run
      [mResult[0], getReplicationConfig(ldap), expected]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1][/rid=(\S+)/, 1].to_i == data[2]
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'zmldapreplicatool rid test' => {"IS"=>data[1], "SB"=>'rid=' + data[2]}}
      end
    end,

    v(cb('syncrepl masterURI test') do
      backup = getReplicationConfig(ldap)[/provider=(\S+)/, 1] rescue nil
      expected = 'ldap://foo.com:1234/'
      mResult = ZMLdapreplicatool.new('-m', expected).run
      syncrepl = getReplicationConfig(ldap)
      ZMLdapreplicatool.new('-m', backup).run if !backup.nil?
      [mResult[0], syncrepl, expected]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1][/provider=(\S+)/, 1] == data[2]
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'zmldapreplicatool masterURI test' => {"IS"=>data[1], "SB"=>'provider=' + data[2]}}
      end
    end,

    v(cb('syncrepl invalid rid test') do
      expected = getReplicationConfig(ldap)
      rand(0-999) + 1000
      mResult = ZMLdapreplicatool.new('-r', rand(0-999) + 1000).run
      [mResult[0], getReplicationConfig(ldap), expected]
    end) do |mcaller, data|
      mcaller.pass = data[0] != 0 && data[1][/rid=(\d+)\s+/, 1] == data[2][/rid=(\d+)\s+/, 1]
    end,

    v(cb('syncrepl startTLS test') do
      backup = getReplicationConfig(ldap)[/starttls=(\S+)/, 1] rescue nil
      next [1, backup] if backup.nil?
      expected = backup == 'critical' ? 'off' : 'critical'
      mResult = ZMLdapreplicatool.new('-t', expected).run
      syncrepl = getReplicationConfig(ldap)
      ZMLdapreplicatool.new('-t', backup).run if !backup.nil?
      [mResult[0], syncrepl, expected == 'off' ? nil : expected]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1][/starttls=(\S+)/, 1] == data[2]
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'zmldapreplicatool startTLS test' => {"IS"=>data[1], "SB"=>data[2].nil? ? 'off' : 'critical'}}
      end
    end
  ]
  end,

  #TODO: check that the syncrepl modification is only rid#, master,...
  # replace=>{olcSyncrepl=>"$replEntry"},
  # replace=>{olcUpdateRef=>"$masterURI"},
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
