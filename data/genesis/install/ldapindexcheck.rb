#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
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
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmlocalconfig"
require 'action/zmprov'
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap indexes test"

include Action 

(mCfg = ConfigParser.new()).run
expected = {
            'objectClass' => 'eq',
            'zimbraForeignPrincipal' => 'eq',
            'zimbraYahooId' => 'eq',
            'zimbraId' => 'eq',
            'zimbraMemberOf' => 'eq',
            'zimbraSharedItem' => 'eq,sub',
            'zimbraVirtualHostname' => 'eq',
            'zimbraVirtualIPAddress' => 'eq',
            'zimbraAuthKerberos5Realm' => 'eq',
            'zimbraMailCatchAllAddress' => 'eq,sub',
            'zimbraMailDeliveryAddress' => 'eq,sub',
            'zimbraMailForwardingAddress' => 'eq',
            'zimbraMailAlias' => 'eq,sub',
            'zimbraMailHost' => 'eq',
            'zimbraMailTransport' => 'eq',
            'zimbraDomainName' => 'eq,sub',
            'zimbraShareInfo' => 'sub',
            'uid' => 'pres,eq',
            'mail' => 'pres,eq,sub',
            'cn' => 'pres,eq,sub',
            'displayName' => 'pres,eq,sub',
            'sn' => 'pres,eq,sub',
            'givenName' => 'pres,eq,sub',
            'zimbraCalResSite' => 'eq,sub',
            'zimbraCalResBuilding' => 'eq,sub',
            'zimbraCalResFloor' => 'eq,sub',
            'zimbraCalResRoom' => 'eq,sub',
            'zimbraCalResCapacity' => 'eq',
            'entryUUID' => 'eq',
            'entryCSN' => 'eq',
            'zimbraACE' => 'sub',
            'zimbraDomainAliasTargetID' => 'eq',
            'zimbraUCServiceId' => 'eq',
            'DKIMIdentity' => 'eq',
            'DKIMSelector' => 'eq',
           }
expected.merge!({'reqStart' => 'eq', 'reqEnd' => 'eq', 'reqResult' => 'eq'}) if ZMProv.new('gas', 'ldap').run[1].split(/\n/).length > 1 ||
                                                                                mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmldapenablereplica', 'any', '')

ignore = ['dn2id', 'id2entry']
skipOnInstallOnly = ['displayName',
                     'givenName',
                     'reqEnd',
                     'reqResult',
                     'reqStart',
                     'zimbraACE',
                     'zimbraAuthKerberos5Realm',
                     'zimbraCalResBuilding',
                     'zimbraCalResCapacity',
                     'zimbraCalResFloor',
                     'zimbraCalResRoom',
                     'zimbraCalResSite',
                     'zimbraMailCatchAllAddress',
                     'zimbraForeignPrincipal',
                     'zimbraMailForwardingAddress',
                     'zimbraShareInfo',
                     'zimbraVirtualHostname',
                     'zimbraVirtualIPAddress',
                     'zimbraYahooId',
                     'zimbraSharedItem',
                     'zimbraMemberOf',
                     ]
master = ZMLocal.new('ldap_master_url').run[/\/\/([^:\.]+)/, 1]
masterHost = Model::Host.new(master, Model::TARGETHOST.domain)

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("config check") do
    mObject = RunCommandOn.new(masterHost, 'cat', 'root',
                               File.join(Command::ZIMBRAPATH,'data/ldap/config/cn=config', 'olcDatabase={*}mdb.ldif'))
    data = mObject.run
    result = Hash[*data[1].split(/\n/).select {|w| w =~ /^olcDbIndex:\s+/}.collect {|y| y.strip.sub(/^olcDbIndex:\s+/, '').split(" ")}.flatten]
    [data[0], result]
  end) do |mcaller, data|
    result = data[1]
    mcaller.pass = data[0] == 0 && result == expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        errs = {}
        (expected.keys & result.keys).select {|w| expected[w] != result[w]}.each do |mindex|
          errs[mindex] = {"IS" => result[mindex], "SB" => expected[mindex]}
        end
        (expected.keys - result.keys).each do |mindex|
          errs[mindex] = {"IS" => "Missing", "SB" => expected[mindex]}
        end
        (result.keys - expected.keys).each do |mindex|
          errs[mindex] = {"IS" => result[mindex], "SB" => "Missing"}
        end
        mcaller.badones = {'data/ldap/config/cn=config check' => errs}
    end
  end,

  v(cb("ldap index check") do 
    mObject = RunCommandOn.new(masterHost, 'ls', Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH, 'data', 'ldap', 'hdb', 'db', '*.bdb'), '2>&1')
    mResult = mObject.run
    [mResult[0], mResult[1].split(/\n/).select { |w| w =~ /\.bdb/}. collect { |w| File.basename(w.chomp, ".bdb")} - ignore]
  end) do |mcaller, data|
    mcaller.pass = !Utils::isUpgradeFrom('7\.\d+\.\d') && data[0] != 0 &&
                   !data[1].grep(/No such file or directory/).empty? ||
                   Utils::isUpgradeFrom('7\.\d+\.\d') && data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr_reader :badones
        attr_writer :badones
      end
      mcaller.badones = {'ldap index check' => {"IS" => "#{data[1]}, exit code #{data[0]}",
                                                "SB" => (Utils::isUpgradeFrom('7\.\d+\.\d') ? '*.bdb found' : 'No such file or directory') +
                                                        ", exit code #{data[0]}"}}
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