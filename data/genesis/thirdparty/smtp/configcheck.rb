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
require "action/zmprov" 
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Smtp config test"

include Action 

(mCfg = ConfigParser.new).run
isRelease = RunCommand.new('grep', 'root', 'zimbra-core', File.join(Command::ZIMBRAPATH, '.install_history')).run[1].split(/\n/).last =~ /GA/
paramToCheck = {'always_add_missing_headers' => 'yes',
                'smtp_use_tls' => 'no',
                'smtpd_sasl_auth_enable' => 'yes',
                'smtpd_recipient_restrictions' => ['reject_non_fqdn_recipient', 'permit_sasl_authenticated', 'permit_mynetworks',
                                                   'reject_unlisted_recipient', 'reject_invalid_helo_hostname', 'reject_non_fqdn_sender',
                                                   'permit'].join(', '),
                'smtpd_relay_restrictions' => ['permit_sasl_authenticated', 'permit_mynetworks', 'reject_unauth_destination'].join(', '),
                'smtpd_tls_security_level' => begin
                                                mResult = ZMProv.new('gcf', 'zimbraMtaTlsSecurityLevel').run
                                                if(mResult[1] =~ /Data\s+:/)
                                                  mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
                                                end
                                                mResult[1].chomp.split(/:\s*/)[1]
                                              end,
                'mail_version' => OSL::LegalApproved['postfix'],
                'lmtp_host_lookup' => 'dns',
                'relayhost' => begin
                                 sb = ''
                                 mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'server', 'zimbraMtaRelayHost')
                                 mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraMtaRelayHost') if mCustom == false
                                 sb = mCustom[/zimbraMtaRelayHost\s+([^;\s]+)/, 1] if mCustom != false
                                 sb
                               end,
                'canonical_maps' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-canonical.cf'),
                'transport_maps' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-transport.cf'),
                'virtual_alias_domains' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-vad.cf'),
                'virtual_alias_maps' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-vam.cf'),
                'virtual_mailbox_domains' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-vmd.cf'),
                'virtual_mailbox_maps' => File.join('proxy:ldap:', Command::ZIMBRAPATH, 'conf', 'ldap-vmm.cf'),
                'smtpd_use_tls' => 'yes',
                'smtpd_enforce_tls' => 'no',
}


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mCfg.getServersRunning('mta').map do |x|
  [
    v(RunCommandOn.new(x, 'postconf','zimbra')) do |mcaller, data|
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s*([^\s}].*?)\s+\}/m, 1]
      end
      result = paramToCheck.keys.collect {|w| (v = data[1][/^#{w} = ([^\n]+)\n/, 1]).nil? ? [w, 'Missing'] : [w, v]} 
      mcaller.pass = result.select {|w| w[1] != paramToCheck[w[0]]}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - postfix configuration' => {}}
        result.select {|w| w[1] != paramToCheck[w[0]]}.map do |w|
          mcaller.badones[x + ' - postfix configuration'][w[0]] = {"IS"=>w[1], "SB"=>paramToCheck[w[0]]}
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
      end   
    end,
    
    v(cb("Certificates check") do
      server = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                                '-m', 'nokey', 'zimbra_server_hostname').run[1].chomp
      mResult = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmprov'), Command::ZIMBRAUSER, 'gs', server).run
  	  smtpPort = mResult[1][/zimbraSmtpPort:\s+(\S+)\s*$/, 1]
      res = {}
      exitCode = 0
      [['465', 'quit'], ['587 -starttls smtp', 'quit'], [smtpPort.to_s + ' -starttls smtp', 'quit']].each do |opts|
      
        mObject = RunCommandOn.new(x, "/opt/zimbra/common/bin/openssl", 'zimbra', 's_client',
                                  '-connect', server + ":" + opts[0],
                                  '-CApath /opt/zimbra/conf/ca/', '< /dev/null', '2>&1')
         data = mObject.run

        mObject1 = RunCommandOn.new(x, "/opt/zimbra/common/bin/openssl", 'root', 's_client',
                                  '-connect', server + ":" + opts[0],
                                  '-CApath /opt/zimbra/conf/ca/', '< /dev/null', '2>&1')
          data = mObject1.run
        
        
        
        if data[0] != 0 || data[1][/(read:errno=0|OK.*closing connection)|OK LOGOUT completed|[vV]erify return(\s+code)?:\s*0/] == nil ||
           data[1][/verify error:num=([02-9]\d*|1[0-8]?)\s+/] != nil
          iResult = data[1]
          if(iResult =~ /Data\s+:/)
            iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
          end
          res['openssl s_client -connect ' + server + ':' + opts[0]] = {"IS" => iResult, "SB" => 'connection successful'}
          exitCode += 1
        end
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == {}
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = data[1]
      end
    end,
    
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER)) do |mcaller, data|
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s*([^\s}].*?)\s+\}/m, 1]
      end
      result = Hash[*data[1].split(/\n/).select {|w| w =~ /^postfix.*=.*postfix/}.collect {|w| w.chomp.split(/\s+=\s+/)}.flatten]
      #puts result
      mcaller.pass = data[0] == 0 && result.values.select {|w| w =~ /postfix-/}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - localconfig check' => {}}
        result.keys.select {|w| result[w] =~ /postfix-/}.collect {|w| mcaller.badones[x + ' - localconfig check'][w] = {"IS" => result[w], "SB"=> result[w].gsub(/postfix[^\/]+/, "postfix")}}
      end   
    end,
    
    v(RunCommand.new('grep', Command::ZIMBRAUSER, 'server_host',
                     File.join(Command::ZIMBRAPATH, 'conf', 'ldap-*.cf'), Model::Host.new(x))) do |mcaller, data|
      ldapUrl = ZMLocalconfig.new('-m nokey', 'ldap_url', Model::Host.new(x)).run[1].chomp
      mcaller.pass = data[0] == 0 && (hosts = data[1].split(/\n/)).size == 8 &&
                     (urls = hosts.collect {|w| w[/server_host\s+=\s+(.*)/, 1]}.uniq).size == 1 && urls.first == ldapUrl 
    end,
    ]
  end,
  
  #don't include uiwebapps servers
  mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}.map do |x|
    v(cb("Certificates check") do
      server = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmlocalconfig'), Command::ZIMBRAUSER,
                                '-m', 'nokey', 'zimbra_server_hostname').run[1].chomp
      mResult = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin', 'zmprov'), Command::ZIMBRAUSER, 'gs', server).run
      imapPort = mResult[1][/zimbraImapSSLBindPort:\s+(\S+)\s*$/, 1]
      pop3Port = mResult[1][/zimbraPop3SSLBindPort:\s+(\S+)\s*$/, 1]
      res = {}
      exitCode = 0
      [[imapPort, 'a01 logout'], [pop3Port, 'quit']].each do |opts|
        #mObject = RunCommandOn.new(x, "echo \"#{opts[1]}\" | /opt/zimbra/openssl/bin/openssl", 'root', 's_client',
        
        
        mObject = RunCommandOn.new(x, "/opt/zimbra/common/bin/openssl", 'zimbra', 's_client',
                                  '-connect', server + ":" + opts[0],
                                  '-CApath /opt/zimbra/conf/ca/', '< /dev/null', '2>&1')
            data = mObject.run

       mObject1 = RunCommandOn.new(x, "/opt/zimbra/common/bin/openssl", 'root', 's_client',
                                  '-connect', server + ":" + opts[0],
                                  '-CApath /opt/zimbra/conf/ca/', '< /dev/null', '2>&1')
            data = mObject1.run

        
        
        
        if data[0] != 0 || data[1][/(read:errno=0|OK.*closing connection)|OK LOGOUT completed|[vV]erify return(\s+code)?:\s*0/] == nil ||
           data[1][/verify error:num=([02-9]\d*|1[0-8]?)\s+/] != nil
          iResult = data[1]
          if(iResult =~ /Data\s+:/)
            iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
          end
          res['openssl s_client -connect ' + server + ':' + opts[0]] = {"IS" => iResult, "SB" => 'connection successful'}
          exitCode += 1
        end
      end
      [exitCode, res]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] == {}
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = data[1]
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