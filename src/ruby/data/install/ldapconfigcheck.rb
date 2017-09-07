#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2013 Zimbra
#
# ldap config tests.  

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require 'stringio'
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmlocalconfig"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require 'net/ldap'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap config test"

include Action

(mCfg = ConfigParser.new).run
expected = {'olcDatabase={2}mdb,cn=config' => {:olcDbCheckpoint => ['0 0']},
            'olcDatabase={3}mdb,cn=config' => {:olcDbCheckpoint => ['0 0']},
            'cn=config'                    => {:olcTLSCipherSuite => ['MEDIUM:HIGH'], :olcTLSProtocolMin => ['3.1']}
           }
expected.default = {'foo' => []}
  
server = 'UNDEFINED'
ldapUrl = 'UNDEFINED'
zimbraUser = 'UNDEFINED'
zimbraPassword = 'UNDEFINED'

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [

  mCfg.getServersRunning('ldap').map do |x|
    v(cb("ldap config check") do
      mResult = RunCommand.new('libexec/zmslapcat', Command::ZIMBRAUSER, '-c', Command::ZIMBRATMPPATH, h = Model::Host.new(x)).run
      backup = File.join(Command::ZIMBRATMPPATH, 'ldap-config.bak')
      next([mResult[0], {"IS" => "zmslapcat failure - #{mResult[1]}", "SB" => 'Success'}, backup]) if mResult[0] != 0
      mResult = RunCommand.new('cat', Command::ZIMBRAUSER, backup, h).run
      next([mResult[0], {"IS" => "backup retrieval - #{mResult[1]}", "SB" => 'Success'}, backup]) if mResult[0] != 0
      entries = Net::LDAP::Dataset.read_ldif(StringIO.new(mResult[1])).to_entries()
      isReplica = !XPath.match(mCfg.doc, "//host[@name='#{x}']/package[@name='zimbra-ldap']/option[@name='replica']").empty? rescue false
      isMmr = XPath.match(mCfg.doc, "//child::plugin[@name='runZmCommand' and option='#{x}'][option[contains(., 'zmldappromote-replica-mmr')]]").size > 0 rescue false
      # olcDatabase={3}mdb,cn=config exists only on mmr nodes
      expected['olcDatabase={3}mdb,cn=config'] = expected.default if mCfg.getServersRunning('ldap').size == 1 || isReplica && !isMmr
      mResult = {}
      expected.each_pair do |k, v| 
        entry = (cfg = entries.select {|w| w.dn =~ /^#{Regexp.escape(k)}$/}).empty? ? expected.default : cfg.first
        mResult[k] = Hash[v.keys.collect{|w| [w, entry[w]]}.compact]
      end
      [0, mResult]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == expected
    end
  end,

  mCfg.getServersRunning('ldap').map do |x|     
  [ #  get ldapUrl
    v(ZMLocalconfig.new('ldap_url', h = Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !(ldapUrl = data[1][/ldap_url\s+=\s+(ldap\S+)/, 1]).nil?
      if (not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = { x + ' - ldap_url' => {"IS"=>ldapUrl, "SB"=>'non nil'}}
      end
    end,

    # get zimbraUser
    v(ZMLocalconfig.new('zimbra_ldap_userdn', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !(zimbraUser = data[1][/zimbra_ldap_userdn\s+=\s+(.*)/, 1]).nil?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = { x + ' - zimbra_ldap_userdn' => {"IS"=>ldapUrl, "SB"=>'non nil'}}
      end
    end,
      
    # get zimbraPassword
    v(ZMLocalconfig.new('-s', 'zimbra_ldap_password', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && !(zimbraPassword = data[1][/zimbra_ldap_password\s+=\s+(.*)/, 1]).nil?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = { x + ' - zimbra_ldap_password' => {"IS"=>ldapUrl, "SB"=>'non nil'}}
      end
    end,
      
    # check that the passwords are encrypted with SHA512
    v(cb("get ldap users") do
      mResult = [0,0]
      ldap = Net::LDAP.new(:host => ldapUrl[/ldaps?:\/\/([^:]+).*/, 1],
                           :port => ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1],
                           :auth => {:method => :simple,
                                     :username => zimbraUser, #"uid=zimbra,cn=admins,cn=zimbra",
                                     :password => zimbraPassword},#"zimbra"}
                           :encryption => ldapUrl =~ /ldaps/ ? {:method => :simple_tls} : nil
                          )
      begin
        ldap.bind #or raise "bind failed"
        mResult = [0, ldap.search(:base => "", :filter => '(objectclass=inetOrgPerson)', :attributes => ['userPassword', 'createTimestamp'])]
      rescue Net::LDAP::LdapError => e
        mResult = [1, "ldap bind failed " + $! + "(#{e.class}) (#{ldap.host}, #{ldap.port}, #{zimbraUser}, #{zimbraPassword})"]
      end
      mResult
    end) do |mcaller, data|
      # on upgrades from pre 8.0.8 all passwords are SHA encrypted and
      # zmreplica, zmnginx, zmpostfix, and zmamavis account passwords are not encrypted
      expected = Utils::isUpgradeFrom('(7\.\d|8\.0)\.') ? '(512)?' : '512'
      includeSpecial = !Utils::isUpgradeFrom('(7\.\d|8\.0)\.')
      users = data[1].select {|w| w[:dn].first.to_str !~ /zm(replica|nginx|postfix|amavis)/ || includeSpecial}
      mcaller.pass = data[0] == 0 && !data[1].empty? &&
                     (errs = users.select {|w| !w[:userPassword].empty?}.select {|w| w[:userPassword].first.to_str !~ /^\{SSHA#{expected}/}).empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines")
        mcaller.badones = { x + ' - passwords' => errs.collect {|w| {w[:dn].first.to_str => {'IS' => w[:userPassword].first.to_str, 'SB' => "{SSHA#{expected}}..."}}}.flatten}
      end
    end,
    
  ]
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