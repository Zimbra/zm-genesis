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
require "action/zmprov"
require "action/verify"
require 'model/user'
require 'model/json/request'
require 'model/json/loginrequest'
require 'model/json/getcertrequest'
#require 'net/https'
require 'json'
require 'action/json/login'
require 'action/json/getserver'
require 'action/json/getcert'
require "action/buildparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require "action/zmlocalconfig"
require "action/zmcertmgr"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server certificates check"


include Action
include Action::Json
include Model
include Model::Json

server = ZMLocal.new('zimbra_server_hostname').run

selfCert = { 'subject' => %r'(/OU=Zimbra( Collaboration (Suite|Server))?)?/CN=#{server}',
              'issuer' => %r'(/OU=Zimbra( Collaboration (Suite|Server))?)?/CN=#{server}'}          
                   
            
commCert = {'subject' => %r'/?C=US/ST=(California|Texas)/L=(Palo Alto|Frisco)/O=(VMware|Zimbra), Inc./(OU=IT/)?CN=\*.eng.(vmware|zimbra).com',
            'issuer'  => %r'/?C=US/O=DigiCert Inc/(OU=www.digicert.com/)?CN=DigiCert (High Assurance CA-3|(SHA2 )?Secure Server CA)'}
expected = selfCert
(mCfg = ConfigParser.new()).run
mHost = Model::TARGETHOST
expected = commCert if mCfg.requireCommercialCert
expected = commCert if !(XPath.first(mCfg.doc, "//plugin[option[@name='test']='plugins/commcert.rb' && option[@name='host']='#{mHost.to_s}']") rescue nil).nil?

#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#
current.action = [
  [mCfg.getServersRunning('store').first].map do |x|
    v(cb("Certificates check", 300) do
      toks = x.split('.')
      target = Host.new(toks[0], toks[1..-1].join('.'))
      #target = Host.new('zqa-121', 'eng.vmware.com')
      admin = Utils::getAdmins.first
      port = '7071'
      port = '9071' if ZMProv.new('gcf', 'zimbraReverseProxyAdminEnabled', target).run[1] =~ /TRUE/
      alogin = AdminLogin.new(AdminLoginRequest.new(admin), target, 7071, 'https').run
      mResult = GetServer.new(admin, target).run
      next(mResult) if mResult[0] != 0
      mServer = mResult[1]
      mResult = GetCertificates.new(admin, mServer.id, target).run
      next(mResult) if mResult[0] != 0
      mCertificates = mResult[1]
      [0, mCertificates]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].keys.select do |k|
        data[1].method('subject').call(k) !~ expected['subject'] ||
        data[1].method('issuer').call(k) !~ expected['issuer']
      end.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        if data[0] != 0
          mcaller.badones = {'Execution error' => {"SB" => 'Success, exit code 0', "IS" => data[1]}}
        else
          errors = {}
          data[1].each_key do |k|
            ['subject', 'issuer'].each do |crt|
              next if expected[crt] =~ data[1].method(crt).call(k)
              errors[k] = {crt =>{"IS" => data[1].method(crt).call(k), "SB" => expected[crt].source}}
            end
          end
          mcaller.badones = errors
        end
      end
    end
  end,
  
  v(cb("truststore check") do
    stores = mCfg.getServersRunning('store')
    next([]) if !stores
    next([]) if ZMLocal.new('mailboxd_server').run.split(/\s+/)[-1] != 'jetty'
    res = {}
    aliases = ['my_ca']
    aliases.push('zcs-user-commercial_ca') if mCfg.requireCommercialCert
    stores.each do |host|
      testDomain = Domain.new(Utils::zimbraHostname[/[^.]+\.(.*)/, 1])
      myHost = Host.new(host[/(.*)\.#{testDomain}/, 1], testDomain)
      javaHome = ZMLocal.new(myHost, 'zimbra_java_home').run
      kpasswd = ZMLocal.new(myHost,'mailboxd_truststore_password').run
      keystore = ZMLocal.new(myHost,'mailboxd_truststore').run
      errs = {}
      aliases.each do |ca|
        mObject = RunCommandOn.new(myHost, File.join(javaHome, 'bin', 'keytool'), 'root',
                                   '-list', '-v',
                                   '-storepass', kpasswd,
                                   '-keystore', keystore,
                                   '-alias', ca)
        mResult = mObject.run
        if mResult[0] != 0
          errs[ca] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1] ? mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1] : mResult[1]
        else
          if ca == 'my_ca'
              cert = selfCert
            else
              cert = commCert
            end
          errs[ca] = mResult[1] if mResult[1][/Issuer:\s*(.*)/, 1].split(/,\s*/).reverse.join('/') !~ cert['issuer']
        end
      end
      res[host] = errs if !errs.empty?
    end
    res
  end) do |mcaller, data| 
    mcaller.pass = data.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data.each_pair do |host, error|
        errs = {}
        error.each_pair do |ca, msg|
          if ca == 'my_ca'
            type = 'self'
          else
            type = 'commercial'
          end
          errs[type] = {"SB" => 'found',
                        "IS" => msg[/(keytool error:.*)$/, 1]
                       }
        end
        msgs[host] = errs
      end
      mcaller.badones = {'truststore test' => msgs}
    end
  end,
  
  v(cb("hash check") do
    stores = mCfg.getServersRunning('store')
    next([]) if !stores
    next([]) if ZMLocal.new('mailboxd_server').run.split(/\s+/)[-1] != 'jetty'
    res = {}
    stores.each do |host|
      testDomain = Domain.new(Utils::zimbraHostname[/[^.]+\.(.*)/, 1])
      myHost = Host.new(host[/(.*)\.#{testDomain}/, 1], testDomain)
      mObject = RunCommandOn.new(myHost, 'ls', 'root',
                                   '-l', File.join(Command::ZIMBRAPATH, 'conf', 'ca'))
      mResult = mObject.run
      if mResult[0] != 0
        res[host] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1] ? mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1] : mResult[1]
      else
        hashes = mResult[1].split(/\n/).select {|w| w =~ /\.pem/}.select {|w| w =~ /->/}.collect {|w| w[/(\S+\s+->\s+\S+)/, 1]}
        if !(dups = hashes.collect{|w| w[/\s+->\s+(\S+)/, 1]}.inject({}) {|h,v| h[v]=h[v].to_i+1; h}.reject{|k,v| v==1}.keys).empty?
          res[host] = hashes.select {|w| dups.include?(w[/->\s+(\S+)/, 1])}
        end
      end
    end
    res
  end) do |mcaller, data| 
    mcaller.pass = data.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data.each_pair do |host, error|
        msgs[host] = {"SB" => 'one hash per each pem file',
                      "IS" => error
                     }
      end
      mcaller.badones = {'hash test' => msgs}
    end
  end,
  
  mCfg.getServersRunning('store').map do |x|
    v(RunCommandOn.new(x, File.join(Command::ZIMBRACOMMON, 'bin', 'openssl'), 'root', 'x509', '-text', '-in', File.join(Command::ZIMBRAPATH, 'ssl', 'zimbra', 'ca', 'ca.pem'))) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     !(notBefore = data[1][/Not Before\s*:\s*(.*)$/, 1]).nil? &&
                     !(notAfter = data[1][/Not After\s*:\s*(.*)$/, 1]).nil? &&
                     (DateTime.parse(notAfter) - DateTime.parse(notBefore)).to_i == 1825
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - self signed CA certificate validity' => {"IS" => "#{(DateTime.parse(notAfter) - DateTime.parse(notBefore)).to_i} days", "SB" => '1825 days'}}
      end
    end
  end,
    
  if expected == selfCert || !Utils::isUpgrade
  [
    v(ZMCertmgr.new('viewstagedcrt', 'self')) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     !(notBefore = data[1][/notBefore=(.*)/, 1]).nil? &&
                     !(notAfter = data[1][/notAfter=(.*)/, 1]).nil? &&
                     (DateTime.parse(notAfter) - DateTime.parse(notBefore)).to_i == 1825
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'self signed certificate validity' => {"IS" => "#{(DateTime.parse(notAfter) - DateTime.parse(notBefore)).to_i} days", "SB" => '1825 days'}}
      end
    end
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
