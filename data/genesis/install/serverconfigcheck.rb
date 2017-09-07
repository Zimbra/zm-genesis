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
require "action/buildparser"
require 'time'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Server config test"


include Action 

existing = {}
expected = {}
server = 'UNDEFINED'
ldapUrl = ZMLocal.new('ldap_url').run.split(/\s+/)[-1]
zimbraUser = ZMLocal.new('zimbra_ldap_userdn').run
zimbraPassword = ZMLocal.new('zimbra_ldap_password').run
if Utils::isAppliance
  require 'ldap'
  ldap = LDAP::Conn.new(ldapUrl[/ldaps?:\/\/([^:]+).*/, 1], port=ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1].to_i)
  ldap.set_option( LDAP::LDAP_OPT_PROTOCOL_VERSION, 3 )
  ldap.bind(zimbraUser, zimbraPassword, LDAP::LDAP_AUTH_SIMPLE)
else
  require 'net/ldap'
  ldap = Net::LDAP.new(:host => ldapUrl[/ldaps?:\/\/([^:]+).*/, 1],
                       :port => ldapUrl[/ldaps?:\/\/[^:]+:(.*)$/, 1],
                       :auth => {:method => :simple,
                                 :username => zimbraUser, #"uid=zimbra,cn=admins,cn=zimbra",
                                 :password => zimbraPassword},#"zimbra"}
                       :encryption => ldapUrl =~ /ldaps/ ? {:method => :simple_tls} : nil
                      )
#begin
#  ldap.bind #or raise "bind failed"
#rescue Net::LDAP::LdapError => e
#  raise StandardError, "ldap bind failed " + $! + "(#{e.class}) (#{ldap.host}, #{ldap.port}, #{zimbraUser}, #{zimbraPassword})"
#end
end
(mCfg = ConfigParser.new).run
(mServerCfg = AttributeParser.new('server')).run

convertdHosts = ['localhost', mCfg.getServersRunning('convertd')]
def myNetwork4(server)
  mResult=RunCommandOn.new(server, '/sbin/ifconfig', 'root', "| grep \"inet \" | grep -v \"127.0.0.1\"").run[1][/(.*)\.\d+/, 1]
  if mResult =~ /inet addr:\d+/
    net = mResult[/inet addr:(\S+)/, 1]
    toks = mResult[/Mask:(\S+)/, 1].split('.')
    m = (toks[0].to_i << 24) + (toks[1].to_i << 16) + (toks[2].to_i << 8) + toks[3].to_i
  else
    net = mResult[/inet\s+(\S+)/, 1]
    #m = mResult[/netmask\s+(\S+)/, 1].hex
    toks = mResult[/netmask\s+(\S+)/, 1].split('.')
    m = (toks[0].to_i << 24) + (toks[1].to_i << 16) + (toks[2].to_i << 8) + toks[3].to_i
  end
  toks = net.split('.')
  n = ((toks[0].to_i << 24) + (toks[1].to_i << 16) + (toks[2].to_i << 8) + toks[3].to_i) & m
  net = ((n >> 24) & 0xff).to_s + "." + ((n >> 16) & 0xff).to_s + "." +((n >> 8) & 0xff).to_s + "." +(n & 0xff).to_s
  i = 31
  while (m >>= 1) & 0x1 == 0
    i -= 1
  end
  return ['127\.0\.0\.0\/8', Regexp.escape(net) + '\/' + i.to_s]
end

def myNetwork6(server)
  mResult=RunCommandOn.new(server, '/sbin/ifconfig', 'root').run
  eth = mResult[1][/(\S+)\s+Link encap:Ethernet/, 1]
  nets = Hash[*mResult[1].split(/\n/).select {|w| w =~ /inet6 addr:/}.collect {|w| w[/inet6 addr:\s*(\S+\s+\S+)/, 1].split}.flatten.reverse]
  if !nets.empty?
    res = ['\[' + nets['Scope:Host'].gsub('/', '\]\/')]
    res.push('\[' + nets['Scope:Global'].gsub(/(^([\da-fA-F]+:){4})(.*)(\/\S+)/, '\1:\]\4')) if nets.has_key?('Scope:Global')
    res.push('\[' + nets['Scope:Link'][/[^:]+/] + '::' + "(%#{eth})?" + '\]\/64')
  else
    nets = Hash[*mResult[1].split(/\n/).select {|w| w =~ /inet6\s+\S+\s+prefixlen/}.collect {|w| w[/inet6\s+(\S+\s+prefixlen\s+\S+)/, 1].split(/\s+prefixlen\s+/)}.flatten]
    res = []
    nets.each_pair do |k, v|
      if k =~ /^:/
        res.push('\[' + k + '\]\/' + v)
      else
        res.push('\[' + k.split(':').first + '::\]\/' +v)
      end
    end
  end
  res
end


#TODO: may want to regexp check the following attrs
exceptions = {'cn' => Utils::Test.new('default') {|sb, is| is[0] =~ /\w+(\.\w+)+$/},
              'description' => Utils::Test.new('some text') {|sb, is| true},
              'zimbraACE' => Utils::Test.new('Zimbra access control list or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraReverseProxyClientCertCA' => Utils::Test.new('CA certificate for authenticating client certificates in nginx proxy (https only) or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraAttachmentsScanURL' => Utils::Test.new('scan class or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraBackupReportEmailRecipients' => Utils::Test.new('email or missing') {|sb, is| is[0] =~ /^(\w+@[^.]+(\.[^.]+)+|Missing)+$/},
              'zimbraBackupReportEmailSender' => Utils::Test.new('email or missing') {|sb, is| is[0] =~ /^(\w+@[^.]+(\.[^.]+)+|Missing)$/},
              'zimbraClusterType' => Utils::Test.new('TRUE') do |sb, is|
                                       hasPackage = begin
                                         mCfg.isPackageInstalled('zimbra-cluster')
                                       rescue
                                         true
                                       end
                                       if !hasPackage
                                         true
                                       else
                                         is[0] =~ /\bRedHat\b/
                                       end
                                     end,
              'zimbraConvertdURL' => Utils::Test.new("http://(#{convertdHosts.join('|')}):7047/convert") do |sb, is|
                                       convertdHosts = [Utils::zimbraHostname] if Utils::isAppliance
                                       if BuildParser.instance.targetBuildId =~ /_FOSS/i || mCfg.getServersRunning('convertd').empty?
                                         is[0] =~ /#{existing.default}/
                                       else
                                         #get all servers running convertd
                                         is[0] =~ /http:\/\/(#{convertdHosts.join('|')}):7047\/convert\b/
                                       end
                                     end,
              'zimbraCreateTimestamp' => Utils::Test.new("optional") do |sb, is, host|
                                           begin
                                             if Utils::isAppliance
                                               config = ldap.search2("cn=#{Utils::zimbraHostname(Model::Host.new(host))},cn=servers,cn=zimbra",
                                                                     LDAP::LDAP_SCOPE_SUBTREE,
                                                                     "(objectclass=*)", ['createTimestamp'])
                                             else
                                               config = ldap.search(:base => "cn=#{Utils::zimbraHostname(Model::Host.new(host))},cn=servers,cn=zimbra",
                                                                    :attributes => ['createTimestamp'])
                                             end
                                             (Utils::isUpgradeFrom('5.0.\d+') && is[0] =~ /Missing/) || Time.parse(config.first['createTimestamp'].first) - Time.parse(is[0]) <= 2
                                           rescue Exception => e
                                             raise StandardError, "ldap bind failed " + $!.class.to_s + "(#{e.to_s}) (#{ldap.host}, #{ldap.port}, #{zimbraUser}, #{zimbraPassword})"
                                             false
                                           end
                                         end,
              'zimbraDNSMasterIP' => Utils::Test.new("DNS server ip(s)") do |sb, is|
                                       dns = XPath.first(mCfg.doc, "//host[@name='#{server}']/package[@name='zimbra-dnscache']") rescue nil
                                       dnsIp = 'Missing'
                                       if !dns.nil?
                                         dnsIp = XPath.first(dns, "//option[@name='zimbraDNSMasterIP']").text rescue '10.210.0.166'
                                       end
                                       is[0] == dnsIp
                                     end,
              'zimbraHsmPolicy' => Utils::Test.new("message,document:before:-30days") do |sb, is|
                                     is[0] =~ /\bmessage,document:before:-30days\b/
                                   end,
              'zimbraHttpDosFilterMaxRequestsPerSec'=> Utils::Test.new("30 or from install template") do |sb, is|
                                                         mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'server', 'zimbraHttpDosFilterMaxRequestsPerSec')
                                                         mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraHttpDosFilterMaxRequestsPerSec') if mCustom == false
                                                         next is[0] =~ /30\b/ if mCustom == false
                                                         is[0] == mCustom[/zimbraHttpDosFilterMaxRequestsPerSec\s+(\d+)/, 1]
                                                       end,
              'zimbraHttpProxyURL' => Utils::Test.new('Missing or vmware proxy') {|sb, is| is[0] =~ /(Missing|http:\/\/proxy\.vmware\.com:3128)/},
              'zimbraId' => Utils::Test.new('id') {|sb, is| is[0] =~ /^[a-f0-9-]+$/},
              'zimbraIMBindAddress' => Utils::Test.new('Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraImapAdvertisedName' => Utils::Test.new('hostname or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraImapBindAddress' => Utils::Test.new(Utils.isUpgrade() ? Provision::ServerConfig['zimbraImapBindAddress'][1] : 'Missing') do |sb, is|
                                           sb = 'Missing'
                                           sb = Provision::ServerConfig['zimbraImapBindAddress'][1] if Utils.isUpgrade()
                                           is[0] == sb
                                         end,
              'zimbraImapBindPort' => Utils::Test.new(Utils::isAppliance ? '143' : '143 or 7143') do |sb, is|
                                        next is[0] == '143' if Utils::isAppliance
                                        is[0] =~ /^[7]?143$/
                                      end,
              'zimbraImapCleartextLoginEnabled' => Utils::Test.new('TRUE if zimbra-proxy') do |sb, is|
                                                     next is[0] == 'TRUE' if Utils::isAppliance
                                                     hasStore = mCfg.getServersRunning('store').include?(server)
                                                     storeWithProxyEnabled = hasStore and mCfg.hasOption('zimbra-store', 'zimbraMailProxy', 'TRUE')
                                                     hasProxy = mCfg.getServersRunning('proxy').include?(server)
                                                     mailProxyEnabled = hasProxy and mCfg.hasOption('zimbra-proxy', 'MAILPROXY', 'TRUE')
                                                     val = (storeWithProxyEnabled or mailProxyEnabled) ? 'TRUE' : 'FALSE'
                                                     is[0] =~ /\b#{val}\b/
                                                   end,
              'zimbraImapMaxRequestSize' => Utils::Test.new('10240 on install, imap_max_request_size on upgrades from 6.0.0-6') do |sb, is|
                                              sb = '10240'
                                              if Utils.isUpgrade() && Utils.isUpgradeFrom('6\.0\.[0-6]_')
                                                sb = ZMLocal.new('qa_imap_max_request_size').run
                                                sb = '10240' if sb =~ /Warning: null valued key/
                                              end
                                              is[0] == sb
                                            end,
              'zimbraImapProxyBindPort' => Utils::Test.new('143 or 7143') {|sb, is| is[0] =~ /^[7]?143$/},
              'zimbraImapDisabledCapability' => Utils::Test.new('disabled capabilities or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraImapSSLBindAddress' => Utils::Test.new(Utils.isUpgrade() ? Provision::ServerConfig['zimbraImapSSLBindAddress'][1] : 'Missing') do |sb, is|
                                              sb = 'Missing'
                                              sb = Provision::ServerConfig['zimbraImapSSLBindAddress'][1] if Utils.isUpgrade()
                                              is[0] == sb
                                            end,
              'zimbraImapSSLBindPort' => Utils::Test.new('993 or 7993') {|sb, is| is[0] =~ /^[7]?993$/},
              'zimbraImapSSLProxyBindPort' => Utils::Test.new('993 or 7993') {|sb, is| is[0] =~ /^[7]?993$/},
              'zimbraImapSSLDisabledCapability' => Utils::Test.new('disabled capabilities or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraInvalidLoginFilterMaxFailedLogin' => Utils::Test.new("10 or from install template") do |sb, is|
                                                            mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'server', 'zimbraInvalidLoginFilterMaxFailedLogin')
                                                            mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraInvalidLoginFilterMaxFailedLogin') if mCustom == false
                                                            next is[0] =~ /10\b/ if mCustom == false
                                                            is[0] == mCustom[/zimbraInvalidLoginFilterMaxFailedLogin\s+(\d+)/, 1]
                                                          end,
              'zimbraIPMode' => Utils::Test.new('ipv4 or ipv6 or both') do |sb, is|
                                  ip_mode = XPath.first(mCfg.doc, "//host[@name='#{server}']/option[@name='zimbraIPMode']").text rescue sb[0]
                                  next is[0] == ip_mode
                                end,
              'zimbraIsMonitorHost' => Utils::Test.new('true or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraLdapGentimeFractionalSecondsEnabled' => Utils::Test.new("TRUE on fresh install, FALSE on upgrades from <8.7.0") do |sb, is|
                                                               if Utils.isUpgradeFrom('8\.[0-6]\.\d+')
                                                                 next is[0] == 'FALSE'
                                                               end
                                                               is[0] == sb[0]
                                                             end,
              'zimbraLmtpAdvertisedName' => Utils::Test.new('hostname or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraLmtpBindAddress' => Utils::Test.new('ip addresses or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraLocale' => Utils::Test.new('locale, e.g. en_US') {|sb, is| true},
              'zimbraLowestSupportedAuthVersion' => Utils::Test.new("#{mServerCfg.attributes['zimbraLowestSupportedAuthVersion']['default']} on install, #{mServerCfg.upgradeValue('zimbraLowestSupportedAuthVersion').first} on upgrade") do |sb, is|
                                                      if !Utils::isUpgrade
                                                        is[0] == sb[0]
                                                      else
                                                        is[0] == mServerCfg.upgradeValue('zimbraLowestSupportedAuthVersion').first
                                                      end
                                                    end,
              'zimbraMailLastPurgedMailboxId' => Utils::Test.new('number') {|sb, is| is[0] =~ /(\d+|Missing)/},
              'zimbraMailLocalBind' => Utils::Test.new('FALSE | TRUE') do |sb, is|
                                         is[0] =~ /TRUE|FALSE|Missing/
                                       end,
              'zimbraMailMode' => Utils::Test.new(Utils::isAppliance ? 'both' : 'http, https, mixed') do |sb, is|
                                    next is[0] == 'both' if Utils::isAppliance
                                    next is[0] =~ /(http|https|mixed)/ if mCfg.getServersRunning('store').include?(server)
                                    is[0] =~ /Missing/
                                  end,
              'zimbraMailProxyPort' => Utils::Test.new('proxy port') do |sb, is|
                                         is[0] =~ /(80){1,2}|Missing/
                                       end,
              'zimbraMailPort' => Utils::Test.new('web server port') do |sb, is|
                                    is[0] =~ /(80){1,2}|Missing/
                                  end,
              'zimbraMailReferMode' => Utils::Test.new('always or wronghost or reverse-proxied') do |sb, is| 
                                         hasStore = mCfg.getServersRunning('store').include?(server)
                                         host = mCfg.doc.get_elements('//host').select {|w| w.attributes['name'] == server ||
                                                                                            w.elements['zimbrahost'].attributes['name'] == server rescue false}.first rescue nil
                                         next false if host.nil? #shouldn't get here
                                         options = host.elements.select {|w| w.attributes['name'] == 'zimbra-store'}.first.get_elements('option')
                                         val = (hasStore and (options.select {|w| w.attributes['name'] == 'zimbraWebProxy'}.first.text.strip == 'TRUE' rescue true)) ? 'reverse-proxied' : 'wronghost'
                                         is[0] =~ /\b#{val}\b/
                                       end,
              'zimbraMailSSLProxyPort' => Utils::Test.new('proxy ssl port') do |sb, is|
                                            is[0] =~ /8?443|Missing/
                                          end,
              'zimbraMailSSLPort' => Utils::Test.new('web server ssl port') do |sb, is|
                                       is[0] =~ /8?443|Missing/
                                     end,
              'zimbraMailTrustedIP' => Utils::Test.new('ip list or missing') {|sb, is| is[0] =~ /(\d{1,3}(\.\d{1,3}){3}|Missing)/},
              'zimbraMailURL' => Utils::Test.new("/ on install, /zimbra on upgrades from <= 8.0.0_BETA1") do |sb, is|
                                   if Utils.isUpgrade() && Utils.isUpgradeFrom('((6|7).\d+.|8.0.0_BETA1)')
                                     sb[0] = '/zimbra'
                                   end
                                   is[0] == sb[0]
                                 end,
              'zimbraMemcachedBindAddress' => Utils::Test.new('interface or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraMemcachedClientServerList' => Utils::Test.new('default to empty') do |sb, is|
                                                     mServers = mCfg.getServersRunning('memcached').collect {|w| w+':11211'} || ['Missing']
                                                     is[0] =~ /Missing/ || mServers.include?(is[0])
                                                   end,
              'zimbraMilterBindAddress' => Utils::Test.new('default to empty') do |sb, is|
                                             is[0] =~ /Missing/
                                           end,
              'zimbraMtaAuthHost' => Utils::Test.new('store host name') do |sb, is|
                                       next is[0] =~ /^[^.]+(\.\w+)+$/ if mCfg.getServersRunning('mta').include?(server) && Utils::isUpgradeFrom('(7\.\d\.|8\.[0-5])')
                                       is[0] =~ /Missing/
                                     end,
              'zimbraMtaAuthTarget' => Utils::Test.new('TRUE on store enabled node') {|sb, is| is[0] =~ /TRUE/},
              'zimbraMtaAuthURL' => Utils::Test.new('https?://hostname/service/soap/') do |sb, is|
                                      next is[0] =~ /^https?:\/\/[^.]+(\.[^.]+)+:\d+\/service\/soap\/$/ if mCfg.getServersRunning('mta').include?(server) && Utils::isUpgradeFrom('(7\.\d\.|8\.[0-5])')
                                      is[0] =~ /Missing/
                                    end,
              #'zimbraMtaMilters' => Utils::Test.new('postfix smtpd_milters') {|sb, is| is[0] =~ /Missing/},
              'zimbraMtaMyHostname' => Utils::Test.new('postfix myhostname') {|sb, is| is[0] =~ /Missing/},
              'zimbraMtaMyNetworks' => Utils::Test.new("ipv4 and ipv6 networks or none(non mta node)") do |sb, is|
                                         next is[0] =~ /Missing/ if !mCfg.getServersRunning('mta').include?(server)
                                         val = myNetwork4(server)
                                         val += myNetwork6(server).to_a if !Utils::isUpgradeFrom('7\.\d+\.\d')
                                       end,
              'zimbraMtaMyOrigin' => Utils::Test.new('postfix myorigin or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraMtaNonSmtpdMilters' => Utils::Test.new('postfix non_smtpd_milters') {|sb, is| is[0] =~ /Missing/},
              'zimbraMtaRelayHost'=> Utils::Test.new("Missing or from install template") do |sb, is|
                                       mCmd = mCfg.zimbraCustomized(Utils.zimbraHostname, 'zmprov', 'mcf', 'zimbraMtaRelayHost')
                                       next is[0] =~ /Missing\b/ if mCmd == false
                                       is[0] == mCmd[/zimbraMtaRelayHost\s+([^;\s]+)/, 1]
                                     end,
              'zimbraMtaSmtpdMilters' => Utils::Test.new('postfix smtpd_milters') do |sb, is|
                                           is[0] =~ /Missing/
                                         end,
              'zimbraMtaTlsAuthOnly' => Utils::Test.new('FALSE on upgrade') do |sb, is|
                                          val = if Utils::isUpgrade()
                                                  Provision::ServerConfig['zimbraMtaTlsAuthOnly'][1]
                                                else
                                                  'TRUE'
                                                end
                                          is[0] == val
                                        end,
              'zimbraMtaTlsSecurityLevel' => Utils::Test.new('may') do |sb, is|
                                               is[0] =~ /may/
                                             end,
              'zimbraNotes' => Utils::Test.new('administrative notes') {|sb, is| true},
              'zimbraNotifyBindAddress' => Utils::Test.new('interface or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraNotifySSLBindAddress' => Utils::Test.new('interface or missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraPop3AdvertisedName' => Utils::Test.new('hostname or Missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraPop3BindAddress' => Utils::Test.new(Utils.isUpgrade() ? Provision::ServerConfig['zimbraPop3BindAddress'][1] : 'Missing') do |sb, is|
                                           sb = 'Missing'
                                           sb = Provision::ServerConfig['zimbraPop3BindAddress'][1] if Utils.isUpgrade()
                                           is[0] == sb
                                         end,
              'zimbraPop3BindPort' => Utils::Test.new(Utils::isAppliance ? '110' : '110 or 7110') do |sb, is|
                                        next is[0] == '110' if Utils::isAppliance
                                        is[0] =~ /^[7]?110$/
                                      end,
              'zimbraPop3CleartextLoginEnabled' => Utils::Test.new('TRUE if zimbra-proxy') do |sb, is|
                                                     next is[0] == 'TRUE' if Utils::isAppliance
                                                     hasStore = mCfg.getServersRunning('store').include?(server)
                                                     storeWithProxyEnabled = hasStore and mCfg.hasOption('zimbra-store', 'zimbraMailProxy', 'TRUE')
                                                     hasProxy = mCfg.getServersRunning('proxy').include?(server)
                                                     mailProxyEnabled = hasProxy and mCfg.hasOption('zimbra-proxy', 'MAILPROXY', 'TRUE')
                                                     val = (storeWithProxyEnabled or mailProxyEnabled) ? 'TRUE' : 'FALSE'
                                                     is[0] =~ /\b#{val}\b/
                                                   end,
              'zimbraPop3ProxyBindPort' => Utils::Test.new('110 or 7110') {|sb, is| is[0] =~ /^[7]?110$/},
              'zimbraPop3SSLBindAddress' => Utils::Test.new(Utils.isUpgrade() ? Provision::ServerConfig['zimbraPop3SSLBindAddress'][1] : 'Missing') do |sb, is|
                                              sb = 'Missing'
                                              sb = Provision::ServerConfig['zimbraPop3SSLBindAddress'][1] if Utils.isUpgrade()
                                              is[0] == sb
                                            end,
              'zimbraPop3SSLBindPort' => Utils::Test.new('995 or 7995') {|sb, is| is[0] =~ /^[7]?995$/},
              'zimbraPop3SSLProxyBindPort' => Utils::Test.new('995 or 7995') {|sb, is| is[0] =~ /^[7]?995$/},
              'zimbraReverseProxyUpstreamEwsServers' => Utils::Test.new('mail stores') do |sb, is|
                                                          next is[0] == 'Missing' if BuildParser.instance.targetBuildId =~ /_FOSS/i
                                                          (mCfg = ConfigParser.new()).run
                                                          servers = mCfg.getServersRunning('store')
                                                          is.sort == servers.sort
                                                        end,
              'zimbraReverseProxyUpstreamLoginServers' => Utils::Test.new('mail stores') do |sb, is|
                                                            (mCfg = ConfigParser.new()).run
                                                            servers = mCfg.getServersRunning('store')
                                                            is.sort == servers.sort
                                                          end,
              'zimbraRedoLogDeleteOnRollover' => Utils::Test.new('FALSE') {|sb, is| is[0] =~ /\bFALSE\b/},
              'zimbraReverseProxyAdminEnabled' => Utils::Test.new("whether to turn on admin console proxy") do |sb, is|
                                                    (mCfg = ConfigParser.new).run
                                                    mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraReverseProxyAdminEnabled')
                                                    next is[0] == sb[0] if mCustom == false
                                                    is[0] == mCustom[/zimbraReverseProxyAdminEnabled\s+([^;\s]+)/, 1]
                                                  end,
              'zimbraReverseProxyAvailableLookupTargets' => Utils::Test.new("The mailstore service servers list") do |sb, is|
                                                              (mCfg = ConfigParser.new()).run
                                                              # don't include web UI servers
                                                              servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}
                                                              is.sort == servers.sort
                                                            end,

              'zimbraReverseProxyDefaultRealm' => Utils::Test.new('Missing if no proxy') do |sb, is|
                                                    hasPackage = begin
                                                      mCfg.isPackageInstalled('zimbra-proxy')
                                                    rescue
                                                      true
                                                    end
                                                    hasPackage ? true : is[0] =~ /Missing/
                                                  end,
              'zimbraReverseProxyHttpEnabled' => Utils::Test.new('TRUE or FALSE') do |sb, is|
                                                   is[0] =~ /TRUE|FALSE/
                                                 end,
              'zimbraReverseProxyLookupTarget' => Utils::Test.new('TRUE') {|sb, is| is[0] =~ /TRUE/},
              'zimbraReverseProxyMailMode' => Utils::Test.new('https') do |sb, is, host|
                                                hasPackage = begin
                                                  #mCfg.isPackageInstalled('zimbra-proxy')
                                                  mCfg.getServersRunning('proxy').include?(host)
                                                rescue
                                                  true
                                                end
                                                if !hasPackage
                                                  true
                                                else
                                                  mObject = ZMLocal.new(h = Host.new(host), 'zimbra_server_hostname')
                                                  srv = mObject.run
                                                  mObject = ZMProv.new('gs', srv)
                                                  data = mObject.run
                                                  iResult = data[1]
                                                  if(iResult =~ /Data\s+:/)
                                                    iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
                                                  end
                                                  if iResult[/zimbraReverseProxyHttpEnabled:\s+(.*)/, 1] == 'FALSE'
                                                    true
                                                  else
                                                    if Utils::isUpgradeFrom('((6|7)(\.\d){2}|8\.0\.0_BETA[1-4])')
                                                      is[0] =~ /http\b/
                                                    else
                                                      is[0] =~ /https\b/
                                                    end
                                                  end
                                                end
                                              end,
              'zimbraReverseProxySSLCiphers' => Utils::Test.new('Proxy SSL Ciphers') do |sb, is|
                                                  sb[0] = sb[0].split(':')
                                                  sb[0] = sb[0] + ['!3DES', 'ECDHE-ECDSA-RC4-SHA', 'ECDHE-RSA-RC4-SHA', 'RC4-SHA'] - ['!RC4'] if Utils::isUpgradeFrom('(7|8)\.[0-6]\.\d+')
                                                  is[0].split(':').sort == sb[0].sort
                                                end,
              'zimbraReverseProxySSLToUpstreamEnabled' => Utils::Test.new('FALSE on upgrades from pre IM-D4 or TRUE') do |sb, is|
                                                            if Utils.isUpgrade() && Utils.isUpgradeFrom('(6|7).\d+.|8.0.0_BETA(1|2|3)')
                                                              next is[0] == 'FALSE'
                                                            end
                                                            is[0] == sb[0]
                                                          end,
              'zimbraReverseProxyUpstreamEwsServers' => Utils::Test.new('servers running mailbox with EWS functionality') do |sb, is|
                                                          next is[0] == 'Missing' if BuildParser.instance.targetBuildId =~ /_FOSS/i
                                                          (mCfg = ConfigParser.new()).run
                                                          # keep only "service" nodes
                                                          servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='SERVICEWEBAPP']").text rescue 'yes'}
                                                          is.sort == servers.sort
                                                        end,
              'zimbraReverseProxyUpstreamLoginServers' => Utils::Test.new('mail stores') do |sb, is|
                                                            (mCfg = ConfigParser.new()).run
                                                            # keep only "service" nodes
                                                            servers = mCfg.getServersRunning('store').select {|w| 'yes' == XPath.first(mCfg.doc, "//host[@name='#{w}']//option[@name='UIWEBAPPS']").text rescue 'yes'}
                                                            is.sort == servers.sort
                                                          end,
              'zimbraRedoLogProvider' => Utils::Test.new('provider class for redo logging or missing') {|sb, is| true},
              'zimbraSaslGssapiRequiresTls' => Utils::Test.new('FALSE or Missing') do |sb, is|
                                                 if Utils::isUpgradeFrom('6.0.\d+_')
                                                   is[0] == 'Missing' || is[0] == 'FALSE'
                                                 else
                                                   is[0] == 'FALSE'
                                                 end
                                               end,
              'zimbraServerVersion' => Utils::Test.new('server version') do |sb, is|
                                         Utils::upgradeHistory.last =~ /.*#{is[0].gsub(/-|_/, '.')}\./
                                       end,
              'zimbraServerVersionBuild' => Utils::Test.new('build version') do |sb, is|
                                              Utils::upgradeHistory.last =~ /\D#{is[0]}\D/
                                            end,
              'zimbraServerVersionMajor' => Utils::Test.new('major version') do |sb, is|
                                              Utils::upgradeHistory.last =~ /^\D+#{is[0]}\D/
                                            end,
              'zimbraServerVersionMinor' => Utils::Test.new('minor version') do |sb, is|
                                              Utils::upgradeHistory.last =~ /^\D+\d+\.#{is[0]}\.\d/
                                            end,
              'zimbraServerVersionMicro' => Utils::Test.new('micro version') do |sb, is|
                                              Utils::upgradeHistory.last =~ /^\D+(\d+\.){2}#{is[0]}[-_.]/
                                            end,
              'zimbraServerVersionType' => Utils::Test.new('type version') do |sb, is|
                                             Utils::upgradeHistory.last =~ /^\D+(\d+\.){2}\d+\D#{is[0]}[-_.]/
                                           end,
              'zimbraSmtpHostname' => Utils::Test.new(ZMProv.new('gas', 'mta').run[1].split(/\n/).join(" or ")) do |sb, is|
                                        mta = ZMProv.new('gas', 'mta').run[1].split(/\n/)
                                        mta.include?(is[0])
                                      end,
              'zimbraSpellCheckURL' => Utils::Test.new('spell check url') do |sb, is|
                                         next is[0] =~ /^http:\/\/[^.]+(\.[^.]+)+:7780\/aspell.php$/ if mCfg.getServersRunning('spell').include?(server)
                                         is[0] == 'Missing'
                                       end,
              'zimbraSpnegoAuthPrincipal' => Utils::Test.new('spnego auth principal/ootb missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraSpnegoAuthTargetName' => Utils::Test.new('spnego auth target name/ootb missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraSshPublicKey' => Utils::Test.new('public key') do |sb, is|
                                        if Utils::isUpgradeFrom('(7\.\d\.|8\.0\.)[0-6][_.]')
                                          is[0] =~ /ssh-dss\s+.*$/
                                        else
                                          is[0] =~ /ssh-rsa\s+.*$/
                                        end
                                      end,
              'zimbraSSLCertificate' => Utils::Test.new('SSL certificate') {|sb, is| is[0] =~ /-----BEGIN CERTIFICATE-----.*-----END CERTIFICATE-----/m},
              'zimbraSSLPrivateKey' => Utils::Test.new('SSL private key') {|sb, is| is[0] =~ /-----BEGIN( RSA)? PRIVATE KEY-----.*-----END( RSA)? PRIVATE KEY-----/m},
              'zimbraServiceEnabled' => Utils::Test.new('service list') {|sb, is| is[0] =~ /\w+.*/},
              'zimbraServiceInstalled' => Utils::Test.new('service list') {|sb, is| is[0] =~ /\w+.*/},
              'zimbraServiceHostname' => Utils::Test.new('zimbra service hostname') {|sb, is| is[0] =~ /\w+(\.\w+)+/},
              'zimbraUserServicesEnabled' => Utils::Test.new('enabled/disabled/missing') {|sb, is| is[0] =~ /Missing/},
              'zimbraWebClientURL' => Utils::Test.new("weclient URL in split mode") do |sb, is|
                                        (mCfg = ConfigParser.new).run
                                        mCustom = mCfg.zimbraCustomized(Utils::zimbraHostname, 'zmprov', 'globalConfig', 'zimbraWebClientURL')
                                        next is[0] == 'Missing' if mCustom == false
                                        is[0] == mCustom[/zimbraWebClientURL\s+([^;\s]+)/, 1]
                                      end,
              'zimbraXMPPEnabled' => Utils::Test.new("FALSE in upgrade from 4.5.x") do |sb, is|
                                       mObject = HistoryParser.new()
                                       mObject.run
                                       sb = mObject.baseVersion =~ /4\.5/ ? 'FALSE' : 'TRUE'
                                       is[0] == sb
                                     end,
             }
exceptions.default = Utils::Test.new('Missing') {|sb, is| is[0] =~ /Missing/}

existing = {}
expected = {}
existingConfig = {}

configDefaults = {'zimbraMailPort' => '80',
                  'zimbraMailProxyPort' => '8080',
                  'zimbraMailSSLPort' => '443',
                  'zimbraMailSSLProxyPort' => '8443',
                  #'zimbraGalLdapFilterDef' => ['zimbraAccountSync:(&(|(displayName=*%s*)(cn=*%s*)(sn=*%s*)(gn=*%s*)(mail=*%s*)(zimbraMailDeliveryAddress=*%s*)(zimbraMailAlias=*%s*))(|(objectclass=zimbraAccount)(objectclass=zimbraDistributionList))(!(objectclass=zimbraCalendarResource)))',
                  #                                  'zimbraResourceSync:(&(|(displayName=*%s*)(cn=*%s*)(sn=*%s*)(gn=*%s*)(mail=*%s*)(zimbraMailDeliveryAddress=*%s*)(zimbraMailAlias=*%s*))(objectclass=zimbraCalendarResource))']
                 }
globalConfigUpgrade = {'zimbraMessageIdDedupeCacheSize'=>"Missing"}
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
  mCfg.getAllServers.map do |x|
    v(cb("Server config test") do
      mObject = AttributeParser.new('server')
      mObject.run
      expected = mObject.attributes
      exitCode = 0
      result = {}
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH, 'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                                 '-m nokey', 'zimbra_server_hostname')
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      server = iResult.chomp
      mObject = ZMProv.new('gs', server)
      #mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmprov'), Command::ZIMBRAUSER, 'gs', server)
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      next [data[0], iResult] if data[0] != 0
      existing = {}
      toks = nil
      iResult.split(/\n/).each do |line|
        next if line =~ /^#/
        if line =~ /^\S+:\s+.*/
          if toks != nil
            existing[toks[0]] = [] if !existing.has_key? toks[0]
            existing[toks[0]] << toks[1].chomp
          end
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line.chomp.strip
        end
      end
      existing[toks[0]] = [] if !existing.has_key? toks[0]
      existing[toks[0]] << toks[1].chomp
      existing.default = ['Missing']
      iResult = {}
      expected.each_key do |key|
        iResult[key] = existing[key]
      end
      [exitCode, iResult]
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].keys().select do |w|
                                       data[1][w].sort != expected[w]['default'].sort
                                     end.select do |w|
                                       !exceptions[w].call(expected[w]['default'], data[1][w], x)
                                     end.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        if data[0] != 0
          mcaller.badones = {"Server #{server} config test" => {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}}
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
            !exceptions[w].call(expected[w]['default'], data[1][w], x)
          end.each do |w|
            mResult[w] = {"IS" => data[1][w].join(","),
                          "SB" => if exceptions.has_key?(w)
                                    exceptions[w].to_str
                                  else
                                    expected[w]['default'].join(",")
                                  end}
          end
          missingKeys.select do |w|
            expected[w]['default'] != ["Skip - no default"]
          end.each {|w| mResult[w] = {"IS" => "missing", "SB" => expected[w]['default'].join(",")}}
          mcaller.suppressDump("Suppressed log can be very large")
          mcaller.badones = {"Server #{x} config test" => mResult}
        end
      end
    end
  end,
  
  v(cb("Server object test") do
    exitCode = 0
    result = {}
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                             '-m nokey', 'zimbra_server_hostname')
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    server = iResult.chomp
    mObject = ZMProv.new('gs', server)
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
        next if line =~ /^#/
        if line =~ /^\S+:\s+.*/
          if toks != nil
            existing[toks[0]] = [] if !existing.has_key? toks[0]
            existing[toks[0]] << toks[1].chomp
          end
          toks = line.split(/:\s+/, 2)
        else
          toks[1] += line.chomp.strip
        end
      end
      existing[toks[0]] = [] if !existing.has_key? toks[0]
      existing[toks[0]] << toks[1].chomp
      existing.default = ['Missing']
      [exitCode, existing]
    end
  end) do |mcaller, data|
    expected = {'objectClass' => ['zimbraServer'],
               }
    mcaller.pass = data[0] == 0 && expected.keys.select { |k| data[1][k].sort != expected[k].sort}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      #mcaller.badones = {'Server config test' => {}}
      if data[0] != 0
        #mcaller.badones['Server config test'] = {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}
        mcaller.badones = {"Server #{server} object test" => {'Exit code' => {"IS" => "#{data[0]} - #{data[1]}", "SB" => '0 - Success'}}}
      else
        mResult = {}
        expected.keys.select do |w|
          data[1][w].sort != expected[w].sort
        end.select do |w|
          mResult[w] = {"IS" => "[" + data[1][w].sort.join(",") + "]",
                        "SB" => "[" + expected[w].sort.join(",") + "]"
                       }
        end
        mcaller.badones = {"Server #{server} object test" => mResult}
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
