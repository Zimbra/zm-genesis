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
require "action/zmprov"
require "action/verify"
require "#{mypath}/install/attributeparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/historyparser"
require "action/zmlocalconfig"
require "#{mypath}/install/utils"
require "#{mypath}/upgrade/pre/provision"
require 'rexml/document'
include REXML
require 'net/ldap'
require "action/buildparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Ldap replication test"


include Action 

existing = {}
expected = {}
server = 'UNDEFINED'
ldapUrl = ZMLocal.new('ldap_url').run.split(/\s+/)[-1]
zimbraUser = ZMLocal.new('zimbra_ldap_userdn').run
zimbraPassword = ZMLocal.new('zimbra_ldap_password').run
ldap = Net::LDAP.new( :host => ldapUrl[/ldap:\/\/([^:]+).*/, 1],
                      :port => ldapUrl[/ldap:\/\/[^:]+:(.*)$/, 1],
                      :auth => {:method => :simple,
                                :username => zimbraUser, #"uid=zimbra,cn=admins,cn=zimbra",
                                :password => zimbraPassword}#"zimbra"}
                      #:encryption => {:method => :simple_tls}
                    )

ldapHosts = ['localhost']
(mObject = ConfigParser.new()).run
ldapHosts = mObject.getServersRunning('ldap')

def addNewAttribute(host, id)
  zimbraLdifFile = File::join(Command::ZIMBRAPATH, 'openldap', 'etc', 'openldap', 'schema', 'zimbra.ldif')
  zimbraAttrFile = File::join(Command::ZIMBRAPATH, 'conf', 'attrs', 'zimbra-attrs.xml')
  zimbraGcfFile  = File::join(Command::ZIMBRAPATH, 'openldap', 'etc', 'openldap', 'zimbra_globalconfig.ldif')
  tmpFile = File::join('', 'tmp', 'newattr.txt')
  # 2.1b) add attribute to conf/attrs/zimbra-attrs.xml
  newAttribute = '<attr id=\"' + id.to_s + '\" name=\"zimbraQATest\" type=\"string\" max=\"256\" cardinality=\"single\" optionalIn=\"globalConfig\" since=\"6.0.6\">\n' +
                 '  <globalConfigValue>QA</globalConfigValue>\n' +
                 '  <desc>Test replication of a new attribute.</desc>\n' +
                 '</attr>\n\n' +
                 '</attrs>'
  mObject = RunCommandOn.new(host,
                             'echo', Command::ZIMBRAUSER, '-e',
                             "\"#{newAttribute}\" > #{tmpFile}.bak")
  mResult = mObject.run
  return(mResult) if mResult[0] != 0
  mObject = RunCommandOn.new(host, 'sed', Command::ZIMBRAUSER,
                             "\"/<\\\/attrs>/ d\"", zimbraAttrFile,
                             "| cat - #{tmpFile}.bak",
                             "> #{tmpFile}"
                            )
  mResult = mObject.run
  return(mResult) if mResult[0] != 0
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-p', zimbraAttrFile, zimbraAttrFile + '.orig').run
  return(mResult) if mResult[0] != 0
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-f', tmpFile, zimbraAttrFile).run
  return(mResult) if mResult[0] != 0
  # 2.2a) get java version from /opt/zimbra/openldap/etc/openldap/schema/zimbra.ldif
  mObject = RunCommandOn.new(host, 'grep', Command::ZIMBRAUSER,
                             "\"#[[:space:]]*Version:[[:space:]]\" " + zimbraLdifFile)
  mResult = mObject.run
  javaVersion = mResult[1][/#\s*(Version:\s+.*)/, 1]
  # 2.2b) zmjava -Dzimbra.version="<VERSION>" com.zimbra.cs.account.AttributeManager -a generateSchemaLdif -i /opt/zimbra/conf/attrs -o /tmp/zimbra.ldif
  mObject = RunCommandOn.new(host, 'zmjava', Command::ZIMBRAUSER,
                             "-Dzimbra.version=\"#{javaVersion}\"",
                             'com.zimbra.cs.account.AttributeManager',
                             '-a generateSchemaLdif',
                             '-i',
                             File::join(Command::ZIMBRAPATH, 'conf', 'attrs'),
                             '-o', tmpFile)
  mResult = mObject.run
  return(mResult) if mResult[0] != 0
  # 2.3a) backup openldap/etc/openldap/schema/zimbra.ldif
  # 2.3b) cp /tmp/zimbra.ldif openldap/etc/openldap/schema/zimbra.ldif
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-p', zimbraLdifFile, zimbraLdifFile + '.orig').run
  return(mResult) if mResult[0] != 0
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-f', tmpFile, zimbraLdifFile).run
  return(mResult) if mResult[0] != 0
  # 2.4) zmjava -Dzimbra.version="<VERSION>" com.zimbra.cs.account.AttributeManager -a generateGlobalConfigLdif -i /opt/zimbra/conf/attrs -o /tmp/zimbra_globalconfig.ldif
  mObject = RunCommandOn.new(host, 'zmjava', Command::ZIMBRAUSER,
                             "-Dzimbra.version=\"#{javaVersion}\"",
                             'com.zimbra.cs.account.AttributeManager',
                             '-a generateGlobalConfigLdif',
                             '-i',
                             File::join(Command::ZIMBRAPATH, 'conf', 'attrs'),
                             '-o', tmpFile)
  mResult = mObject.run
  return(mResult) if mResult[0] != 0
  # 2.5a)backup openldap/etc/openldap/zimbra_globalconfig.ldif
  # 2.5b) cp /tmp/zimbra_globalconfig.ldif openldap/etc/openldap/zimbra_globalconfig.ldif
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-p', zimbraGcfFile, zimbraGcfFile + '.orig').run
  return(mResult) if mResult[0] != 0
  mResult = RunCommandOn.new(host, 'cp', Command::ZIMBRAUSER, '-f', tmpFile, zimbraGcfFile).run
  return(mResult) if mResult[0] != 0
  # 2.6) libexec/zmldapschema
  mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'libexec', 'zmldapschema'),
                             Command::ZIMBRAUSER).run
  return(mResult) if mResult[0] != 0
  # 2.7) libexec/zmldapapplyldif
  mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'libexec', 'zmldapapplyldif'),
                             Command::ZIMBRAUSER).run
  return(mResult) if mResult[0] != 0
  mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'bin', 'ldap'),
                             Command::ZIMBRAUSER,
                             'stop;',
                             File::join(Command::ZIMBRAPATH, 'bin', 'ldap'), 'start').run
  mResult
end

def getLdaps()
  (mObject = ConfigParser.new()).run
    ldapHosts = mObject.getServersRunning('ldap')
    ldaps = []
    master = nil
    ldapHosts.each do |host|
      myHost = Host.new(host[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
      ldapUrls = ZMLocal.new(myHost, 'ldap_url').run.split(/\s+/)
      lprotocol,lhost,lport = ldapUrls[0].split(/:\/*/)
      if ZMLocal.new(myHost, 'ldap_is_master').run == 'true'
        master = myHost
      else
        ldaps.push(myHost) if !ldaps.include?(myHost)
      end
    end
    ldaps.push(master).reverse!
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
  v(cb("LC test", 600) do
    master = getLdaps().first
    next ([1, 'ldap master not found']) if master.nil?
    mResult = RunCommandOn.new(master, File::join(Command::ZIMBRAPATH, 'libexec', 'zmldapenablereplica'),
                               Command::ZIMBRAUSER).run
    next(mResult) if mResult[0] != 0 && !mResult[1][/Accesslog is already enabled/]
    targets = {'olcAccessLogPurge' => {'path' => '/opt/zimbra/data/ldap/config/cn=config/olcDatabase={3}hdb',
                                       'file' => 'olcOverlay={1}accesslog.ldif',
                                       'test' => '01+00:00 00+04:10',
                                       'backup' => nil,
                                       'lc' => 'ldap_overlay_accesslog_logpurge'
                                      },
               'olcSpCheckpoint' => {'path' => '/opt/zimbra/data/ldap/config/cn=config/olcDatabase={3}hdb',
                                     'file' => 'olcOverlay={0}syncprov.ldif',
                                     'test' => '20 20',
                                     'backup' => nil,
                                     'lc' => 'ldap_overlay_syncprov_checkpoint'
                                    },
               'olcSpSessionlog' => {'path' => '/opt/zimbra/data/ldap/config/cn=config/olcDatabase={3}hdb',
                                     'file' => 'olcOverlay={0}syncprov.ldif',
                                     'test' => '550',
                                     'backup' => nil,
                                     'lc' => 'ldap_overlay_syncprov_sessionlog'
                                    },
              }
    #backup current setup
    testInterval = '10'
    mtaconfigInterval = ZMLocal.new(master, 'zmmtaconfig_interval').run
    mtaconfigInterval = nil if mtaconfigInterval =~ /Warning: null valued key/
    if mtaconfigInterval != testInterval
      mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                                 '-e', "zmmtaconfig_interval=#{testInterval}").run
      mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH, 'bin', 'zmmtactl'), Command::ZIMBRAUSER, 'reload').run
    end
    targets.each_pair do |k,v|
      lc = ZMLocal.new(master, v['lc']).run
      v['backup'] = lc if lc !~ /Warning: null valued key/
    end
    targets.values.each do |lc|
      mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                                 '-e', "#{lc['lc']}=\"#{lc['test']}\"").run
    end
    #wait for ~2 minutes for the new values to be processed
    sleep(120 + testInterval.to_i)
    #check new values
    exitCode = 0
    errs = {}
    targets.values.collect {|w| File.join(w['path'], w['file'])}.uniq.each do |f|
      mObject = RunCommandOn.new(master, 'cat', 'root', f)
      mResult = mObject.run
      next([mResult[0], 'Error retrieving ldap config - ' + mResult[1]]) if mResult[0] != 0
      mResult[1].split(/\n/).each do |line|
        toks = line.split(/:\s+/)
        if targets.keys.include?(toks[0]) && toks[1] != targets[toks[0]]['test']
          errs[toks[0]] = {"IS" => toks[1], "SB" => targets[toks[0]]['test']}
          exitCode += 1
        end
      end
    end
    #restore setup
    targets.values.each do |lc|
      if lc['backup']
        mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                                   '-e', "#{lc['lc']}=\"#{lc['backup']}\"").run
      else
        mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                                   '-u', lc['lc']).run
      end
    end
    if mtaconfigInterval != testInterval
      mCmd = '-u zmmtaconfig_interval'
      mCmd = "-e zmmtaconfig_interval=#{mtaconfigInterval}" if mtaconfigInterval
      mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER, mCmd).run
      mResult = RunCommandOn.new(master, File.join(Command::ZIMBRAPATH, 'bin', 'zmmtactl'), Command::ZIMBRAUSER, 'reload').run
    end
    [exitCode, errs]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"LC test" => data[1]}
    end
  end,

  v(cb("Master-replica diff test") do
    #ldapHosts = ['localhost']
    (mObject = ConfigParser.new()).run
    ldapHosts = mObject.getServersRunning('ldap')
    next([0, 'No replication - Skipping test']) if ldapHosts.length <= 1
    gConfigs = {'master' => {}, 'replica' => {}}
    ldapHosts.each do |host|
      myHost = Host.new(host[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
      ldapUrls = ZMLocal.new(myHost, 'ldap_url').run.split(/\s+/)
      lprotocol,lhost,lport = ldapUrls[0].split(/:\/*/)
      key = ZMLocal.new(myHost, 'ldap_is_master').run == 'true' ? 'master' : 'replica'
      zimbraUser = ZMLocal.new(myHost, 'zimbra_ldap_userdn').run
      zimbraPassword = ZMLocal.new(myHost, 'zimbra_ldap_password').run
      ldap = Net::LDAP.new( :host => lhost,
                            :port => lport,
                            :auth => {:method => :simple,
                                      :username => zimbraUser,
                                      :password => zimbraPassword}
                          )
      begin
        #config = ldap.search( :base => "cn=#{Utils::zimbraHostname},cn=servers,cn=zimbra",
        #                      :attributes => ['createTimestamp'])
        config = Hash.new([key + "Missing"])
        ldap.search( :base => "cn=config,cn=zimbra",
                     :filter => Net::LDAP::Filter.eq( "objectClass", "zimbraGlobalConfig" )) do |entry|
          entry.each do |attribute, values|
            va = []
            values.each {|w| va.push(w.to_s)}
            config[attribute] = va.sort
          end
        end
        #config.delete(:dn) if key == 'replica'
        gConfigs[key] = gConfigs[key].merge({host => config})
      rescue Net::LDAP::LdapError => e
        raise StandardError, "ldap search failed " + $! + "(#{e.class}) (cn=#{Utils::zimbraHostname},cn=servers,cn=zimbra)"
      end
    end
    mhost = gConfigs['master'].keys[0]
    err = gConfigs['replica'].keys.collect do |r|
      (gConfigs['master'][mhost].keys + gConfigs['replica'][r].keys).uniq.select do |attribute|
        gConfigs['master'][mhost][attribute] != gConfigs['replica'][r][attribute]
      end.collect { |attribute| {attribute => {mhost => gConfigs['master'][mhost][attribute],
                                               r => gConfigs['replica'][r][attribute]}}}
    end.delete_if {|x| x.empty?}
    [err.empty? ? 0 : 1, err]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {"config test" => {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}}
      else
        mcaller.badones = {"config test" => data[1]}
      end
    end
  end,

  v(cb("New attribute test", 600) do
    (mObject = ConfigParser.new()).run
    ldapHosts = mObject.getServersRunning('ldap')
    next([0, 'No replication - Skipping test']) if ldapHosts.length <= 1
    master = ''
    replicas = []
    ldapHosts.each do |host|
      myHost = Host.new(host[/(.*)\.#{Model::TestDomain}/, 1], Model::TestDomain)
      ldapUrls = ZMLocal.new(myHost, 'ldap_url').run.split(/\s+/)
      lprotocol,lhost,lport = ldapUrls[0].split(/:\/*/)
      if ZMLocal.new(myHost, 'ldap_is_master').run == 'true'
        master = myHost
      else
        replicas.push(myHost)
      end
    end
    next ([1, 'ldap master not found']) if master == nil
    # 2.1a) get last attribute from conf/attrs/zimbra-attrs.xml
    (mObject = AttributeParser.new).run
    id = mObject.lastId() + 1
    
    mResult = addNewAttribute(master, id)
    next(mResult) if mResult[0] != 0
    # 2.8) zmprov mcf zimbraQATest TRUE
    mResult = RunCommandOn.new(master, File::join(Command::ZIMBRAPATH, 'bin', 'zmprov'), Command::ZIMBRAUSER,
                               '-l', 'mcf', 'zimbraQATest', 'QA').run
    next(mResult) if mResult[0] != 0
    # 2.9) zmprov cs qatest.com
    mResult = RunCommandOn.new(master, File::join(Command::ZIMBRAPATH, 'bin', 'zmprov'), Command::ZIMBRAUSER,
                               '-l', 'cs', 'qatest.com').run
    next(mResult) if mResult[0] != 0
    # 2.10) on replica no server/zimbraQATest(replication stopped)
    replicas.each do |host|
      mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'bin', 'zmprov'), Command::ZIMBRAUSER,
                                 '-l', 'gs', 'qatest.com').run
      break if mResult[0] == 0
    end
    next([1, "replication should have been stopped, command #mResult[1]} should fail"]) if mResult[0] == 0
    errs = {}
    #3) on replica - repeat 2.1-2.7
    # 3.9) zmprov gcf zimbraQATest
    #      zimbraQATest: QA
    replicas.each do |host|
      mResult = addNewAttribute(host, id)
      if mResult[0] != 0
        errs[host] = mResult.dup 
        next
      end
      ###NEED DELAY???
      #mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'bin', 'zmprov'), Command::ZIMBRAUSER,
      #                           'fc', 'config').run
      mResult = RunCommandOn.new(host, File::join(Command::ZIMBRAPATH, 'bin', 'zmprov'), Command::ZIMBRAUSER,
                                 '-l', 'gcf', 'zimbraQATest').run
      errs[host] = mResult[1].dup if mResult[1] !~ /zimbraQATest:\s+QA/
    end
    [errs.empty? ? 0 : 1, errs]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"new attribute replication test" => {"IS" => data[1], "SB" => 'Success'}}
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