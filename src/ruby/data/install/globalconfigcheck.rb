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
require "action/buildparser"
require "action/zmlocalconfig"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "#{mypath}/install/attributeparser"
require "action/zmprov"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Global config test"

include Action 

existing = {}
expected = {}

def getDefaultDomain()
  mResult = ZMProv.new('gcf', 'zimbraDefaultDomainName').run
  if(mResult[1] =~ /Data\s+:/)
    mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
  end
  mResult[1].chomp.split(/:\s*/)[1]
end

(mGlobalCfg = AttributeParser.new('globalConfig')).run
mandatory = {'zimbraReverseProxySSLCiphers' => mGlobalCfg.attributes['zimbraReverseProxySSLCiphers']['default'].first,
            }
(mCfg = ConfigParser.new).run

#TODO: may want to regexp check the following attrs
exceptions = {#'zimbraGalSyncInternalSearchBase' => Utils::Test.new("Missing") {|sb, is| is[0] =~ /Missing/},
              'zimbraAmavisQuarantineAccount' => Utils::Test.new("virus-quarantine.xxxxxxxxx@#{getDefaultDomain()}") do |sb, is|
                                                   is[0] =~ /\bvirus-quarantine\..*@#{Regexp.new(getDefaultDomain())}\b/
                                                 end,
              'zimbraAuthTokenKey' => Utils::Test.new('auth token secret key') {|sb, is| is[0] =~ /[:a-f\d]+\b/},
              'zimbraBackupReportEmailRecipients' => Utils::Test.new('email or missing') do |sb, is|
                                                       next is[0] == Utils::getAdmins.first.to_s if Utils::isAppliance
                                                       is[0] =~ /^(\w+@[^.]+(\.[^.]+)+|Missing)+$/
                                                     end,
              'zimbraBackupReportEmailSender' => Utils::Test.new('email or missing') do |sb, is|
                                                   next is[0] == Utils::getAdmins.first.to_s if Utils::isAppliance
                                                   is[0] =~ /^(\w+@[^.]+(\.[^.]+)+|Missing)$/
                                                 end,
              'zimbraCertAuthorityCertSelfSigned' => Utils::Test.new('Convenience CA certificate') {|sb, is| is[0] =~ /-----BEGIN( TRUSTED)? CERTIFICATE-----.*-----END( TRUSTED)? CERTIFICATE-----/m},
              'zimbraCertAuthorityKeySelfSigned' => Utils::Test.new('Convenience CA key') {|sb, is| is[0] =~ /-----BEGIN( RSA)? PRIVATE KEY-----.*-----END( RSA)? PRIVATE KEY-----/m},
              'zimbraClusterType' => Utils::Test.new('RedHat') {|sb, is| is[0] =~ /RedHat\b/},
              'zimbraContactHiddenAttributes' => Utils::Test.new('dn,zimbraAccountCalendarUserType,member,vcardUID,vcardURL,vcardXProps') do |sb, is|
                                                   is[0].split(/\s*,\s*/).sort == sb[0].split(/\s*,\s*/).sort
                                                 end,
              'zimbraComponentAvailable' => Utils::Test.new('dddd') {|sb, is| is[0] =~ /((HSM|archiving|convertd|hotbackup)(,(HSM|archiving|convertd|hotbackup))*)*\b/},
              'zimbraConvertdURL' => Utils::Test.new("http://#{Utils::zimbraHostname}:7047/convert") do |sb, is|
                                       servers = []
                                       if Utils::isAppliance
                                         is[0] == "http://#{Utils::zimbraHostname}:7047/convert"
                                       elsif BuildParser.instance.targetBuildId =~ /_FOSS/i
                                         is[0] == "Missing"
                                       else
                                         mObject = ConfigParser.new()
                                         mResult = mObject.run
                                         servers = mObject.getServersRunning('convertd')
                                         next is[0] == 'Missing' if servers.empty?
                                         is[0] =~ /http:\/\/#{Regexp.compile(servers.join('|'))}:7047\/convert\b/
                                       end
                                     end,
              'zimbraCsrfTokenKey' => Utils::Test.new('CSRF token secret key') {|sb, is| is[0] == is[0][/([\da-f:]+)/, 1]},
              'zimbraDefaultDomainName' => Utils::Test.new(getDefaultDomain()) {|sb, is| is[0] =~ /\b#{Regexp.new(getDefaultDomain())}\b/},
              'zimbraHttpProxyURL' => Utils::Test.new('Missing or vmware proxy') {|sb, is| is[0] =~ /(Missing|http:\/\/proxy\.vmware\.com:3128)/},
              'zimbraInstalledSkin' => Utils::Test.new('empty|deprecated') do |sb, is|
                                         if Utils.isUpgrade() && Utils.isUpgradeFrom('8\.0\.0_BETA(1|2)')
                                           next is.join(",") =~ /(\w+,)+\w+/
                                         end
                                         is[0] =~ /Missing/
                                       end,
              'zimbraImapCleartextLoginEnabled' => Utils::Test.new("TRUE for appliance else FALSE") do |sb, is|
                                                     Utils::isAppliance ? is[0] == 'TRUE' : is[0] == 'FALSE'
                                                   end,
              'zimbraInvalidLoginFilterMaxFailedLogin' => Utils::Test.new("10 or from install template") do |sb, is|
                                                            mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'server', 'zimbraInvalidLoginFilterMaxFailedLogin')
                                                            mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraInvalidLoginFilterMaxFailedLogin') if mCustom == false
                                                            next is[0] =~ /10\b/ if mCustom == false
                                                            is[0] == mCustom[/zimbraInvalidLoginFilterMaxFailedLogin\s+(\d+)/, 1]
                                                          end,
              'zimbraHsmPolicy' => Utils::Test.new("message,document:before:-(30days|#{(30 * 24 * 60).to_s}minutes)") do |sb, is|
                                     days = "30"
                                     hours = (days.to_i * 24).to_s
                                     minutes = (hours.to_i * 60).to_s
                                     is[0] =~ /\bmessage,document:before:-(#{days}days|#{hours}hours|#{minutes}minutes)\b/
                                   end,
              'zimbraHttpDosFilterMaxRequestsPerSec' => Utils::Test.new("30 or from install template") do |sb, is|
                                                          mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraHttpDosFilterMaxRequestsPerSec') 
                                                          next is[0] =~ /30\b/ if mCustom == false
                                                          is[0] == mCustom[/zimbraHttpDosFilterMaxRequestsPerSec\s+([^;\s]+)/, 1]
                                                        end,
              'zimbraLdapGentimeFractionalSecondsEnabled' => Utils::Test.new("TRUE on fresh install, FALSE on upgrades from <8.7.0") do |sb, is|
                                                               if Utils.isUpgradeFrom('8\.[0-6]\.\d+')
                                                                 next is[0] == 'FALSE'
                                                               end
                                                               is[0] == sb[0]
                                                             end,
              #assume for now that logger is installed on zmhostname
              'zimbraLogHostname' => Utils::Test.new(Utils::zimbraHostname) do |sb, is|
                                       mObject = ConfigParser.new()
                                       mResult = mObject.run
                                       expect = mResult[0] == 0 ? mObject.getServersRunning('logger').first : Utils::zimbraHostname
                                       expect == is[0]
                                     end,
              'zimbraLowestSupportedAuthVersion' => Utils::Test.new("#{mGlobalCfg.attributes['zimbraLowestSupportedAuthVersion']['default']} on install, #{mGlobalCfg.upgradeValue('zimbraLowestSupportedAuthVersion').first} on upgrade") do |sb, is|
                                                  if !Utils::isUpgrade
                                                    is[0] == sb[0]
                                                  else
                                                    is[0] == mGlobalCfg.upgradeValue('zimbraLowestSupportedAuthVersion').first
                                                  end
                                                end,
              'zimbraMailMode' => Utils::Test.new("both for appliance or missing") do |sb, is|
                                    Utils::isAppliance ? is[0] == 'both' : is[0] == 'Missing'
                                  end,
              'zimbraMailProxyReconnectTimeout' => Utils::Test.new("10 on fresh install, 60 on upgrades from 8.6.0") do |sb, is|
                                                     if Utils.isUpgradeFrom('8\.[0-6]\.\d+')
                                                       next is[0] == '60'
                                                     end
                                                     is[0] == sb[0]
                                                   end,
              'zimbraMailURL' => Utils::Test.new("/ on install, /zimbra on upgrades from <= 8.0.0_BETA1") do |sb, is|
                                   if Utils.isUpgrade() && Utils.isUpgradeFrom('((6|7)\.\d+.|8\.0\.0_BETA1)')
                                     sb[0] = '/zimbra'
                                   end
                                   is[0] == sb[0]
                                 end,
              'zimbraMemcachedClientServerList' => Utils::Test.new("list of host:port for memcached servers; set to empty value to disable") do |sb, is|
                                                     mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraMemcachedClientServerList')
                                                     next is[0] == 'Missing' if mCustom == false
                                                     is[0] == mCustom[/zimbraMemcachedClientServerList\s+([^;\s]+)/, 1]
                                                   end,
              'zimbraMtaBlockedExtension'=> Utils::Test.new("Missing") {|sb, is| is[0] =~ /Missing\b/},
              'zimbraMtaCommonBlockedExtension' => Utils::Test.new('[mov, rm, wav, wmf] blocked only on upgrade from 6.0.5-') do |sb, is|
                                                     if Utils::isUpgradeFrom('5\.0\.\d+') || Utils::isUpgradeFrom('6\.0\.[0-5]_')
                                                       diff = ['mov', 'rm', 'wav', 'wmf']
                                                     else
                                                       diff = []
                                                     end
                                                     is - sb == diff && sb - is == []
                                                   end,
              'zimbraMtaRelayHost'=> Utils::Test.new("Missing or from install template") do |sb, is|
                                       mObject = ConfigParser.new()
                                       mResult = mObject.run
                                       next is[0] =~ /Missing\b/ if mResult[0] != 0
                                       mCmd = mObject.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraMtaRelayHost')
                                       next is[0] =~ /Missing\b/ if mCmd == false
                                       is[0] == mCmd[/zimbraMtaRelayHost\s+([^;\s]+)/, 1]
                                     end,
              #'zimbraMtaMyNetworks' => Utils::Test.new('127.0.0.0/8 10.72.83.0/24') {|sb, is| is[0] =~ /127\.0\.0\.0\/8\s+10\.72\.83\.0\/24/},
              'zimbraMtaSmtpdTlsProtocols' => Utils::Test.new('!SSLv2, !SSLv3') {|sb, is| false},
              'zimbraNetworkActivation' => Utils::Test.new('NETWORK license activation record') do |sb, is|
                                             if BuildParser.instance.targetBuildId =~ /FOSS/i
                                               is[0] == 'Missing'
                                             else
                                               is[0] =~ /<ZimbraLicenseActivation verifier="ZV2">.*<\/ZimbraLicenseActivation>/
                                             end
                                           end,
              'zimbraNetworkLicense' => Utils::Test.new('NETWORK license') {|sb, is| is[0] =~ /(<ZimbraLicense verifier="ZV2">.*<\/ZimbraLicense>|Missing)/m},
              'zimbraNotebookAccount' => Utils::Test.new( Utils::isAppliance ? 'Missing' : "wiki@" + getDefaultDomain()) do |sb, is|
                                           next is[0] == 'Missing' if Utils::isAppliance
                                           next is[0] == 'Missing' if !(Utils::isUpgrade() && Utils.isUpgradeFrom('6\.0\.\d+'))
                                           mResult = ZMProv.new('gcf', 'zimbraDefaultDomainName').run
                                           if(mResult[1] =~ /Data\s+:/)
                                             mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
                                           end
                                           defaultDomain = mResult[1].chomp.split(/:\s*/)[1]
                                           is[0] =~ /wiki@#{defaultDomain}\b/
                                         end,
              'zimbraPop3CleartextLoginEnabled' => Utils::Test.new("TRUE for appliance else FALSE") do |sb, is|
                                                     Utils::isAppliance ? is[0] == 'TRUE' : is[0] == 'FALSE'
                                                   end,
              'zimbraPublicServiceHostname' => Utils::Test.new("one of the servers in config or null") do |sb, is|
                                                 is[0] =~ /\b(Missing|.*\.lab\.zimbra\.com)\b/
                                               end,
              'zimbraRedoLogDeleteOnRollover' => Utils::Test.new("FALSE") {|sb, is| is[0] =~ /\bFALSE\b/},
              'zimbraReverseProxyAdminEnabled' => Utils::Test.new("whether to turn on admin console proxy") do |sb, is|
                                                    mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraReverseProxyAdminEnabled')
                                                    next is[0] == sb[0] if mCustom == false
                                                    is[0] == mCustom[/zimbraReverseProxyAdminEnabled\s+([^;\s]+)/, 1]
                                                  end,
              'zimbraReverseProxyAvailableLookupTargets' => Utils::Test.new("The mailstore service servers list") do |sb, is|
                                                              # don't include web UI servers
                                                              servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}
                                                              is.sort == servers.sort
                                                            end,
              'zimbraReverseProxySSLCiphers' => Utils::Test.new(mGlobalCfg.attributes['zimbraReverseProxySSLCiphers']['default'].first) do |sb, is|
                                                  sb = mandatory['zimbraReverseProxySSLCiphers'].split(':')
                                                  sb = sb + ['!3DES', 'ECDHE-ECDSA-RC4-SHA', 'ECDHE-RSA-RC4-SHA', 'RC4-SHA'] - ['!RC4'] if Utils::isUpgradeFrom('(7|8)\.[0-6]\.\d+')
                                                  is[0].split(':').sort == sb.sort
                                                end,
              'zimbraReverseProxySSLToUpstreamEnabled' => Utils::Test.new('FALSE on upgrades from pre IM-D4 or TRUE') do |sb, is|
                                                            if Utils.isUpgrade() && Utils.isUpgradeFrom('(6|7)\.\d+.|8\.0\.0_BETA(1|2|3)')
                                                              next is[0] == 'FALSE'
                                                            end
                                                            is[0] == sb[0]
                                                          end,
              'zimbraReverseProxyUpstreamEwsServers' => Utils::Test.new('servers running mailbox with EWS functionality') do |sb, is|
                                                          next is[0] == 'Missing' if BuildParser.instance.targetBuildId =~ /_FOSS/i
                                                          # keep only "service" nodes
                                                          servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}
                                                          is.sort == servers.sort
                                                        end,
              'zimbraReverseProxyUpstreamLoginServers' => Utils::Test.new('mail stores') do |sb, is|
                                                            # keep only "service" nodes
                                                            servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='UIWEBAPPS']").text rescue 'yes'}
                                                            is.sort == servers.sort
                                                          end,
              'zimbraSkinLogoURL' => Utils::Test.new("Logo URL") do |sb, is| 
                                       if BuildParser.instance.targetBuildId =~ /_FOSS/i
                                         is[0] =~ /http:\/\/www\.zimbra\.com\b/
                                       else
                                         is[0] =~ /Missing/
                                       end
                                     end,
              'zimbraSpamIsNotSpamAccount' => Utils::Test.new("ham.xxxxxxxxx@#{getDefaultDomain()}") {|sb, is| is[0] =~ /\bham\..*@#{Regexp.new(getDefaultDomain())}\b/},
              'zimbraSpamIsSpamAccount' => Utils::Test.new("spam.xxxxxxxxx@#{getDefaultDomain()}") {|sb, is| is[0] =~ /\bspam\..*@#{Regexp.new(getDefaultDomain())}\b/},
              'zimbraVersionCheckInterval' => Utils::Test.new('1d on fresh install, 0 on upgrade/appliance') do |sb, is|
                                                if Utils::isAppliance || 
                                                   Utils::isUpgrade
                                                   #Utils::isUpgradeFrom('5.0.[0-9]') || 
                                                   #Utils::isUpgradeFrom('6.0.[01]_')
                                                  is[0] == "0"
                                                else
                                                  #getting here if check interval is not the default
                                                  false
                                                end
                                              end,
              'zimbraVersionCheckLastAttempt' => Utils::Test.new('empty on upgrades, a timestamp otherwise') do |sb, is|
                                                   is[0] =~ /(\d+Z|Missing)/
                                                 end,
              'zimbraVersionCheckLastResponse' => Utils::Test.new('<?xml version="1.0"?><versionCheck status="0|1">.*</versionCheck> or unset/Missing') do |sb, is|
                                                    is[0] =~ /(<\?xml version="1\.0"\?>(<versionCheck status="\d+">.*<\/versionCheck>)*|Missing)/
                                                 end,
              'zimbraVersionCheckLastSuccess' => Utils::Test.new('timestamp') do |sb, is|
                                                    is[0] =~ /(\d+Z|Missing)/
                                                  end,
              'zimbraVersionCheckNotificationEmail' => Utils::Test.new('email address') do |sb, is|
                                                         next is[0] == Utils::getAdmins.first.to_s if Utils::isAppliance
                                                         mObject = ConfigParser.new()
                                                         mResult = mObject.run
                                                         hasStore = begin
                                                                      mObject.isPackageInstalled('zimbra-store')
                                                                    rescue
                                                                      false
                                                                    end
                                                         !hasStore || is[0] =~ /\S+@\S+/
                                                       end,
              'zimbraVersionCheckNotificationEmailFrom' => Utils::Test.new('email address') do |sb, is|
                                                             next is[0] == Utils::getAdmins.first.to_s if Utils::isAppliance
                                                             mObject = ConfigParser.new()
                                                             mResult = mObject.run
                                                             hasStore = begin
                                                                          mObject.isPackageInstalled('zimbra-store')
                                                                        rescue
                                                                          false
                                                                        end
                                                             #next true if !mObject.hasOption('zimbra-store', 'zimbraVersionCheckNotificationEmailFrom')
                                                             !hasStore || is[0] =~ /\S+@\S+/
                                                           end,
              'zimbraVersionCheckSendNotifications' => Utils::Test.new('FALSE on appliance, check install template otherwise') do |sb, is|
                                                         next is[0] == 'FALSE' if Utils::isAppliance
                                                         mObject = ConfigParser.new()
                                                         mResult = mObject.run
                                                         hasStore = begin
                                                                      mObject.isPackageInstalled('zimbra-store')
                                                                    rescue
                                                                      false
                                                                    end
                                                         next true if !hasStore
                                                         next is[0] == 'FALSE' if !mObject.hasOption('zimbra-store', 'zimbraVersionCheckSendNotifications')
                                                         mObject.hasOption('zimbra-store', 'zimbraVersionCheckSendNotifications', is[0])
                                                       end,
              'zimbraVersionCheckServer' => Utils::Test.new('mbs server zimbra id') do |sb, is|
                                              if Utils::isAppliance
                                                servers = [Utils::zimbraHostname]
                                              else
                                                mObject = ConfigParser.new()
                                                mResult = mObject.run
                                                servers = mObject.getServersRunning('store')
                                              end
                                              servers.collect {|w| ZMProv.new('gs', w, 'zimbraId').run[1][/zimbraId: (\S+)/,1]}.include?(is[0])
                                            end,
              'zimbraVersionCheckURL' => Utils::Test.new('http://www.zimbra.com/aus/universal/update.php') do |sb, is|
                                         if Utils.isUpgrade() && Utils.isUpgradeFrom('((6|7)\.\d+.|8\.0\.0_BETA(1|2))')
                                           next is[0] =~ /^#{Regexp.escape('http://www.zimbra.com/aus/admin/zimbraAdminVersionCheck.php')}$/
                                         end
                                         # non-default setting
                                         is[0] == sb[0]
                                       end,
              'zimbraWebClientURL' => Utils::Test.new("weclient URL in split mode") do |sb, is|
                                        mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraWebClientURL')
                                        next is[0] == 'Missing' if mCustom == false
                                        is[0] == mCustom[/zimbraWebClientURL\s+([^;\s]+)/, 1]
                                      end,
              'zimbraXMPPEnabled' => Utils::Test.new('FALSE on upgrade from < 5.0.6') do |sb, is|
                                       if BuildParser.instance.baseBuildId != BuildParser.instance.targetBuildId
                                         if BuildParser.instance.baseBuildId =~ /FRANKLIN/
                                           is[0] =~ /TRUE\b/
                                           else
                                           is[0] =~ /FALSE\b/
                                           end
                                         else
                                         is[0] =~ /TRUE\b/
                                       end
                                     end,
              }
exceptions.default = Utils::Test.new('Missing') {|sb, is| is[0] =~ /Missing/}
globalConfigUpgrade = {'zimbraMessageIdDedupeCacheSize'=>["Missing"]}
globalConfigAccount = 'globalConfigAccount'

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(cb("Global config defaults test") do
    mObject = AttributeParser.new('globalConfig')
    mObject.run()
    expected = mObject.attributes
    mandatory.each_pair {|k, v| expected[k]['default'] = [v]}
    exitCode = 0
    result = {}
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                             'gacf')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    if data[0] != 0
      [data[0], iResult]
    else
      existing = {}
      toks = nil
      iResult.split(/\n/).each do |line|
        if line =~ /^\S+:\s+.*/
          if toks != nil
            existing[toks[0]] = [] if !existing.has_key? toks[0]
            existing[toks[0]] << toks[1].chomp
          end
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line.chomp
        end
      end
      existing[toks[0]] = [] if !existing.has_key? toks[0]
      existing[toks[0]] << toks[1].chomp
      existing.default = ['Missing']
      iResult = {}
      expected.each_key do |key|
        iResult[key] = existing[key] #if (expected[key] != ["Skip - no default"] || exceptions.has_key?(key))
      end
      [exitCode, iResult]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].keys.select do |w|
                                     data[1][w].sort != expected[w]['default'].sort
                                   end.select do |w|
                                     !exceptions[w].call(expected[w]['default'], data[1][w])
                                   end.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Global config test' => {}}
      if data[0] != 0
        mcaller.badones['Global config test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
      else
        expectedKeys = expected.keys
        realityKeys = data[1].keys
        unexpectedKeys = realityKeys - expectedKeys
        commonKeys = realityKeys - unexpectedKeys
        missingKeys = expectedKeys - realityKeys
        mResult = {}
        realityKeys.select do |w|
          data[1][w].sort != expected[w]['default'].sort
        end.select do |w|
          !exceptions[w].call(expected[w]['default'], data[1][w])
        end.each do |w|
          mResult[w] = {"IS" => data[1][w].sort.join(","),
                        "SB" => if exceptions.has_key?(w)
                                  exceptions[w].to_str
                                else
                                  expected[w]['default'].sort.join(",")
                                end}
        end
        missingKeys.select do |w|
          expected[w] != ["Skip - no default"]
        end.each {|w| mResult[w] = {"IS" => "missing", "SB" => expected[w]['default'].join(",")}}
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
        mcaller.badones['Global config test'] = mResult
      end
    end
  end,
  
  v(cb("Global config upgrade test") do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                             'ga', globalConfigAccount, '2>&1')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    if iResult =~ /account.NO_SUCH_ACCOUNT/
      data[0] = 0
      iResult = []
    else
      iResult = iResult[/^zimbraPrefOutOfOfficeReply.*$/].split(/:\s+/)[1].split('|').collect {|w| w.chomp.strip().split(/:/, 2)}
      iResult = iResult.select {|w| globalConfigUpgrade[w[0]] = [w[1]]; ['3000'] != existing[w[0]]}
    end
    [data[0], iResult]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Global config upgrade test' => {}}
      if data[0] != 0
        mcaller.badones['Global config upgrade test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
      else
        globalConfigUpgrade.each_pair do |key, val|
          next if existing[key] == val
          mcaller.badones['Global config upgrade test'][key] = {"IS" => existing[key].join(","), "SB" => val.join(",")}
        end
      end
    end
  end,
  
  #check for missing gc attributes with default values
  v(ZMProv.new('gacf')) do |mcaller, data|
    allGcWithValues = mGlobalCfg.attributes.select {|k,v| v['default'] != ["Skip - no default"]}
    #delete deprecated if mandated
    if !(XPath.first(mCfg.doc, "//plugin[option[@name='test']='install/deprecation.rb']") rescue nil).nil?
      allGcWithValues = allGcWithValues.delete_if{|k, v| !(w = v['deprecatedSince']).nil? && w =~ /[0-8]\.[0-6]/}
    end
    allGcWithValues = allGcWithValues.collect{|w| w.first}
    mExpected = []
    mcaller.pass = data[0] == 0 && !allGcWithValues.empty? &&
                   (mExpected = allGcWithValues - data[1].split.select {|w| w =~ /.*:$/}.collect {|w| w[/^([^:]+):/, 1]}).empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Global configs attributes' => {"IS" => data[0] == 0 ? "Missing" : "exit code = #{data[0]}",
                                                         "SB" => mExpected.collect {|w| "#{w}=\"#{mGlobalCfg.attributes[w]['default'].join(',')}\""}.join(',')}}
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