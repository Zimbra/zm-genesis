
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
# This test checks for correctness of localconfig.xml file permissions(640)
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
#require "action/zmvolume"
require "action/zmprov"
require "action/buildparser"
require "action/zmlocalconfig"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "#{mypath}/upgrade/pre/provision"
require 'model/deployment'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Localconfig test"

include Action

def getSystemMemory(host)
  mResult = RunCommand.new('uname', 'root', '-s', host).run
  if mResult[1] =~ /linux/i
    mResult = RunCommand.new('cat', 'root', '/proc/meminfo', host).run # | grep ^MemTotal: | awk '{print \$2}'`;
    return sprintf("%0.1f", mResult[1][/MemTotal:\s+(\d+)/, 1].to_f/(1024*1024))
  elsif mResult[1] =~ /darwin/i
    mResult = RunCommand.new('sysctl', 'root', 'hw.memsize', host).run
    return sprintf("%0.1f", mResult[1][/hw.memsize:\s+(\d+)/, 1].to_f/(1024*10240*1024))
  end
  return "0"
end

expectedPermissions = '-rw-r-----\.?' #file mask to check
rootLdapPassword = "UNDEFINED"
zimbraLdapPassword = "UNDEFINED"

(mCfg = ConfigParser.new()).run
ldapPort = '389'
mCfg.doc.each_element_with_attribute('name', 'LDAPPORT',1,'//option') {|e| ldapPort = e.text.strip}
ldapProtocol = ldapPort == '389' ? 'ldap' : 'ldaps'
zLdapPassword = 'whatever'
mCfg.doc.each_element_with_attribute('name', 'LDAPADMINPASS',1,'//option') {|e| zLdapPassword = e.text.strip}
mHost = Model::TARGETHOST

mandatory = {
             'allow_modifying_deprecated_attributes' => Utils::Test.new('missing| false') do |sb, is|
                                                          sb = 'Unset'
                                                          isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'allow_modifying_deprecated_attributes')
                                                          next is == isCustomized[/allow_modifying_deprecated_attributes=(\S+)/, 1] if isCustomized
                                                          is == sb
                                                        end,
             'allow_unauthed_ping' => Utils::Test.new('missing | true') do |sb, is|
                                        sb = 'Unset'
                                        sb = 'true' if !(XPath.first(mCfg.doc, "//plugin[option[@name='test']='install/modeset.rb' and option[@name='host']='#{mHost.to_s}']") rescue nil).nil?
                                        is == sb
                                        true #ignore for now
                                      end,
             'amavis_dspam_enabled' => Utils::Test.new('unset or FALSE by default') do |sb, is|
                                         is =~ /(FALSE|Unset)/
                                       end,
             'antispam_mysql_host' => Utils::Test.new('127.0.0.1 or ::1') do |sb, is|
                                        next is == 'Unset' if !Model::Deployment.getServersRunning('mta').include?(mHost.to_s)
                                        ip_mode = XPath.first(mCfg.doc, "//host[@name='#{mHost.to_str}']/option[@name='zimbraIPMode']").text rescue ""
                                        if ip_mode =~ /(both|ipv6)/
                                            is =~ /::1/
                                        else
                                          is =~ /127\.0\.0\.1/
                                        end
                                      end,
             'av_notify_domain' => Utils::Test.new('a domain') {|sb, is| is =~ /\S+\.com/},
             'av_notify_user' => Utils::Test.new('a user') {|sb, is| is =~ /\S+@\S+\.com/},
             'imap_max_request_size' => Utils::Test.new('same as qa_imap_max_request_size') do |sb, is|
                                          sb = Utils::getLC(mHost, 'imap_max_request_size')[1][0]
                                          sb = '10240' if sb == 'Missing'
                                          sb = 'EMPTY' if sb == ''
                                          is == sb
                                        end,
             'qa_imap_max_request_size' => Utils::Test.new('int or smpty string') {|sb, is| true},
             'javamail_imap_timeout' => Utils::Test.new('install=60, 5.0.x upgrade=20') do |sb, is|
                                          is == '60'
                                        end,
             'javamail_pop3_timeout' => Utils::Test.new('install=60, 5.0.x upgrade=20') do |sb, is|
                                          is == '60'
                                        end,
             'ldap_accesslog_maxsize' => Utils::Test.new('80GB max') do |sb, is|
                                           next true if !mCfg.getServersRunning('ldap').include?(mHost.to_s)
                                           crt = RunCommand.new('df', 'root', '-B1', '/opt/zimbra/data/ldap/mdb/db', mHost).run[1].split(/\n/).last[/\s+(\d+)\s+/, 1]
                                           default = ZMLocal.new(mHost,  '-d', 'ldap_accesslog_maxsize').run
                                           is == crt || is == default
                                         end,
             'ldap_amavis_password' => Utils::Test.new('a password') do |sb, is|
                                         if Model::Deployment.getServersRunning('ldap').include?(mHost.to_s) ||
                                            Model::Deployment.getServersRunning('mta').include?(mHost.to_s)
                                           is.length >= 6
                                         else
                                           is == 'EMPTY'
                                         end
                                       end,
             'ldap_bes_searcher_password' => Utils::Test.new('zmbes-searcher on ldap node; unset otherwise') do |sb, is|
                                               if Model::Deployment.getServersRunning('ldap').include?(mHost.to_s)
                                                 if Utils::isUpgradeFrom('7\.\d+\.\d+|8\.0\.[0-7]')
                                                   is == 'zmbes-searcher'
                                                 else
                                                   is != 'zmbes-searcher'
                                                 end
                                               else
                                                 is == 'EMPTY'
                                               end
                                             end,
             'ldap_cache_account_maxsize' => Utils::Test.new('default 20000') do |sb, is|
                                               isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                               next is =~ /\d+/ if isCustomized && 'ldap_cache_account_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                               is == '20000'
                                             end,
             'ldap_cache_alwaysoncluster_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                                       isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                       next is =~ /\d+/ if isCustomized && 'ldap_cache_account_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                       is == '100'
                                                     end,
             'ldap_cache_cos_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                           isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                           next is =~ /\d+/ if isCustomized && 'ldap_cache_cos_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                           is == '100'
                                         end,
             'ldap_cache_domain_maxsize' => Utils::Test.new('default 500') do |sb, is|
                                              isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                              next is =~ /\d+/ if isCustomized && 'ldap_cache_domain_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                              is == '500'
                                            end,
             'ldap_cache_external_domain_maxsize' => Utils::Test.new('default 10000') do |sb, is|
                                                       isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                       next is =~ /\d+/ if isCustomized && 'ldap_cache_external_domain_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                       is == '10000'
                                                     end,
             'ldap_cache_group_maxsize' => Utils::Test.new('default 2000') do |sb, is|
                                              isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                              next is =~ /\d+/ if isCustomized && 'ldap_cache_group_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                              is == '2000'
                                            end,
             'ldap_cache_reverseproxylookup_domain_maxage' => Utils::Test.new('default 15') {|sb, is| is == '15'},
             'ldap_cache_reverseproxylookup_domain_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                                                 isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                                 next is =~ /\d+/ if isCustomized && 'ldap_cache_reverseproxylookup_domain_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                                 is == '100'
                                                               end,
             'ldap_cache_reverseproxylookup_server_maxage' => Utils::Test.new('default 15') {|sb, is| is == '15'},
             'ldap_cache_reverseproxylookup_server_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                                                 isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                                 next is =~/\d+/ if isCustomized && 'ldap_cache_reverseproxylookup_server_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                                 is == '100'
                                                               end,
             'ldap_cache_right_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                             isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                             next is =~ /\d+/ if isCustomized && 'ldap_cache_right_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                             is == '100'
                                           end,
             'ldap_cache_server_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                              isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                              next is =~ /\d+/ if isCustomized && 'ldap_cache_server_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                              is == '100'
                                            end,
             'ldap_cache_share_locator_maxsize' => Utils::Test.new('default 5000') do |sb, is|
                                                     isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                     next is =~ /\d+/ if isCustomized && 'ldap_cache_share_locator_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                     is == '5000'
                                                   end,
             'ldap_cache_timezone_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                              isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                              next is =~ /\d+/ if isCustomized && 'ldap_cache_timezone_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                              is == '100'
                                            end,
             'ldap_cache_ucservice_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                                 isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                 next is =~ /\d+/ if isCustomized && 'ldap_cache_ucservice_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                 is == '100'
                                               end,
             'ldap_cache_xmppcomponent_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                                     isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                                     next is =~ /\d+/ if isCustomized && 'ldap_cache_xmppcomponent_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                                     is == '100'
                                                   end,
             'ldap_cache_zimlet_maxsize' => Utils::Test.new('default 100') do |sb, is|
                                              isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'ldap_cache.*maxsize')
                                              next is =~ /\d+/ if isCustomized && 'ldap_cache_zimlet_maxsize' =~ /#{isCustomized[/(ldap_cache[\S]+)/, 1]}/
                                              is == '100'
                                            end,
             'ldap_db_maxsize' => Utils::Test.new('80GB max') do |sb, is|
                                    next true if !mCfg.getServersRunning('ldap').include?(mHost.to_s)
                                    crt = RunCommand.new('df', 'root', '-B1', '/opt/zimbra/data/ldap/mdb/db', mHost).run[1].split(/\n/).last[/\s+(\d+)\s+/, 1]
                                    default = ZMLocal.new(mHost,  '-d', 'ldap_accesslog_maxsize').run
                                    is == crt || is == default
                                  end,
             'ldap_host' => Utils::Test.new('hostname') {|sb, is| is =~ /qa\S+\..*\.com/},
             'ldap_is_master' => Utils::Test.new('true or false') {|sb, is| is =~ /(true|false)/},
             'ldap_master_url' => Utils::Test.new("#{ldapProtocol}://zimbrahostname:#{ldapPort}") do |sb, is|
                                    master = ZMProv.new('gas', 'ldap').run[1]
                                    is =~ /#{ldapProtocol}:\/\/(#{master.split(/\n/).join('|')}):#{ldapPort}/
                                  end,
             'ldap_nginx_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6 || is == 'EMPTY' && !Model::Deployment.getServersRunning('ldap').include?(mHost.to_s)},
             'ldap_port' => Utils::Test.new('a port number, default 389') {|sb, is| is =~ /\b#{ldapPort}\b/},
             'ldap_postfix_password' => Utils::Test.new('a password') do |sb, is|
                                          if Model::Deployment.getServersRunning('ldap').include?(mHost.to_s) ||
                                            Model::Deployment.getServersRunning('mta').include?(mHost.to_s)
                                            is.length >= 6
                                          else
                                            is == 'EMPTY'
                                          end
                                        end,
             'ldap_replication_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6 || is == 'EMPTY' && !Model::Deployment.getServersRunning('ldap').include?(mHost.to_s)},
             'ldap_root_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6 || is == 'EMPTY' && !Model::Deployment.getServersRunning('ldap').include?(mHost.to_s)},
             'ldap_starttls_supported' => Utils::Test.new('0|1') {|sb, is| is =~ /\b(0|1)\b/},
             'ldap_url' => Utils::Test.new("#{ldapProtocol}://zimbrahostname:#{ldapPort}...") {|sb, is| is =~ /\b#{ldapProtocol}:\/\/\S+:#{ldapPort}(\s+#{ldapProtocol}:\/\/\S+:#{ldapPort})*\b/},
             'mailboxd_directory' => Utils::Test.new('${zimbra_home}/mailboxd') do |sb, is|
                                       is == '${zimbra_home}/mailboxd' || is == File.join(Command::ZIMBRAPATH, 'mailboxd')
                                     end,
             'mailboxd_java_heap_memory_percent' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'mailboxd_java_heap_size' => Utils::Test.new('max 1536 on 32-bit, .20-.25% of total memory otherwise') do |sb, is|
                                            percent = Utils::getLC(mHost, 'mailboxd_java_heap_memory_percent')[1][0]
                                            percent = '25' if percent == 'Missing'
                                            is.to_i == (percent.to_f / 100 * getSystemMemory(mHost).to_f * 1024).to_i
                                          end,
             'mailboxd_java_options' => Utils::Test.new('java options') do |sb, is|
                                          next true if !mCfg.getServersRunning('store').include?(mHost.to_s)
                                          expected = ZMLocal.new(mHost,  '-d', 'mailboxd_java_options').run
                                          expected.gsub!(/\$\{networkaddress_cache_ttl\}/, '60') if Utils::isUpgradeFrom('8.0.[0-3]\D')
                                          expected.gsub!(/ -Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2 -Djdk.tls.client.protocols=TLSv1,TLSv1.1,TLSv1.2/, '') if Utils::isUpgradeFrom('8\.[05]\.')
                                          ipMode = XPath.first(mCfg.doc, "//host[@name='#{mHost.to_str}']/option[@name='zimbraIPMode']").text rescue nil
                                          expected += ' -Djava.net.preferIPv4Stack=true' if ipMode.nil? || ipMode == 'ipv4'
                                          is.split(/\s+/).sort - ['-XX:-UseSplitVerifier'] == expected.split(/\s+/).sort - ['-XX:-UseSplitVerifier']
                                        end,
             'mailboxd_keystore' => Utils::Test.new('${mailboxd_directory}/etc/keystore') do |sb, is|
                                      if Model::Deployment.getServersRunning('store').include?(mHost.to_s)
                                        is == File.join('${mailboxd_directory}', 'etc', 'keystore') ||
                                        is == File.join(Command::ZIMBRAPATH, 'mailboxd', 'etc', 'keystore')
                                      else
                                        is == File.join(Command::ZIMBRAPATH, 'conf', 'keystore')
                                      end
                                    end,
             'mailboxd_keystore_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6},
             'mailboxd_server' => Utils::Test.new('jetty') do |sb, is|
                                    if Model::Deployment.getServersRunning('store').include?(mHost.to_s)
                                      is =~ /\bjetty\b/
                                    else
                                      is == 'EMPTY'
                                    end
                                  end, #store only
             'mailboxd_truststore' => Utils::Test.new('truststore') do |sb, is|
                                        javaHome = ZMLocal.new('zimbra_java_home').run
                                        is =~ /#{Regexp.compile(javaHome)}.*\/lib\/security\/cacerts/
                                      end,
             'migrate_user_zimlet_prefs' => Utils::Test.new('true on upgrade from 6.0.4-|false|unset on fresh install') do |sb, is|
                                              expected = if Utils::isUpgrade()
                                                           if Utils::isUpgradeFrom('5.0.\d+._') || Utils::isUpgradeFrom('6.0.[0-4]_')
                                                             'true'
                                                           elsif Utils::isUpgradeFrom('6.0.[56]_')
                                                             'false'
                                                           elsif Utils::isUpgradeFrom('6.0.7_')
                                                             nil
                                                           else
                                                             'Unset'
                                                           end
                                                         else
                                                           'Unset'
                                                         end
                                              is == expected
                                            end,
             'mysql_bind_address' => Utils::Test.new('127.0.0.1 or ::1') do |sb, is|
                                        next is == 'Unset' if !Model::Deployment.getServersRunning('store').include?(mHost.to_s)
                                        ip_mode = XPath.first(mCfg.doc, "//host[@name='#{mHost.to_str}']/option[@name='zimbraIPMode']").text rescue ""
                                        if ip_mode =~ /(both|ipv6)/
                                            is =~ /::1/
                                        else
                                          is =~ /127\.0\.0\.1/
                                        end
                                      end,
             'mysql_root_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6},
             'oo_linux_install_path' => Utils::Test.new('libreoffice') do |sb, is|
                                          if BuildParser.instance.targetBuildId =~ /NETWORK/ && Deployment.getServersRunning('store').include?(mHost.to_s)
                                            is =~ /soffice$/
                                          else
                                            is == 'Unset'
                                          end
                                        end,
             'postfix_always_add_missing_headers' => Utils::Test.new('yes|no') {|sb, is| is == 'Unset'},
             'postfix_mail_owner' => Utils::Test.new('default postfix') {|sb, is| is =~ /^_?postfix$/},
             'postfix_setgid_group' => Utils::Test.new('postfix group, default postdrop') {|sb, is| is =~ /^_?postdrop$/},
             'postfix_sender_canonical_maps' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'postfix_transport_maps' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'postfix_virtual_alias_domains' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'postfix_virtual_alias_maps' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'postfix_virtual_mailbox_domains' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'postfix_virtual_mailbox_maps' => Utils::Test.new('Unset') {|sb, is| is == 'Unset'},
             'smtp_destination' => Utils::Test.new('account name, default is admin@') do |sb, is|
                                     if Model::Deployment.getServersRunning('logger').include?(mHost.to_s) ||
                                       Model::Deployment.getServersRunning('snmp').include?(mHost.to_s)
                                       is =~ /\S+@\S+\.com\b/
                                     else
                                       is == 'Unset'
                                     end
                                   end,
             'smtp_notify' => Utils::Test.new('account name, default is admin@') do |sb, is|
                                if Model::Deployment.getServersRunning('snmp').include?(mHost.to_s)
                                  is == 'yes'
                                else
                                  is == 'Unset'
                                end
                              end,
             'smtp_source' => Utils::Test.new('account name, default is admin@') do |sb, is|
                                if Model::Deployment.getServersRunning('logger').include?(mHost.to_s) ||
                                  Model::Deployment.getServersRunning('snmp').include?(mHost.to_s)
                                  is =~ /\S+@\S+\.com\b/
                                else
                                  is == 'Unset'
                                end
                              end, #logger only
             'snmp_notify' => Utils::Test.new('account name, default is admin@') do |sb, is|
                                if Model::Deployment.getServersRunning('snmp').include?(mHost.to_s)
                                  is == 'yes'
                                else
                                  is == 'Unset'
                                end
                              end,
             'snmp_trap_host' => Utils::Test.new('account name, default is admin@') do |sb, is|
                                   if Model::Deployment.getServersRunning('snmp').include?(mHost.to_s)
                                     is == mHost.to_s || is == Model::Deployment.getServersRunning('snmp', false).first #hack for now
                                   else
                                     is == 'Unset'
                                   end
                                 end,
             #'ssl_allow_mismatched_certs' => Utils::Test.new('default true') {|sb, is| is == 'true'},
             #'ssl_allow_untrusted_certs' => Utils::Test.new('enable config restart') do |sb, is|
             #                                 is == 'false'
             #                               end,
             'zimbra_class_store' => Utils::Test.new('default is com.zimbra.cs.store.file.FileBlobStore') do |sb, is|
                                       sb = 'com.zimbra.cs.store.file.FileBlobStore'
                                       hasScality = XPath.first(mCfg.doc, "//plugin[option[last()]='plugins/storagescality.rb' and option[last() - 1]='#{mHost.to_s}']") rescue nil
                                       sb = 'com.zimbra.qa.extentions.httpstore.ScalityHttpStoreManager' unless hasScality.nil?
                                       is == sb
                                     end,
             'ssl_default_digest' => Utils::Test.new('default sha256') {|sb, is| is == 'sha256'},
             'zimbra_dos_filter_max_requests_per_sec' => Utils::Test.new('Unset' ) do |sb, is|
                                                           is == 'Unset'
                                                         end,
             'zimbra_java_home' => Utils::Test.new('java home') do |sb, is|
                                     is =~ /^(\/opt\/zimbra\/(.*\/)?java|\/System\/Library\/Frameworks\/JavaVM.framework\/Versions\/.*\/Home)$/
                                   end,
             'zimbra_gid' => Utils::Test.new('zimbra group id') {|sb, is| is =~ /\b\d+\b/},
             'zimbra_ldap_password' => Utils::Test.new(zLdapPassword) do |sb, is|
                                         sb = zLdapPassword
                                         if Utils::isAppliance || sb == 'whatever'
                                           iResult = RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'localconfig.xml'), mHost).run[1]
                                           doc = Document.new iResult.slice(iResult.index('<?xml version'), iResult.index('</localconfig>') - iResult.index('<?xml version') + '</localconfig>'.length)
                                           doc.each_element_with_attribute('name', 'zimbra_ldap_password', 0, '//key') do |k|
                                             sb = k.elements['value'].text
                                           end
                                         end
                                         is == sb
                                       end,
             'zimbra_mail_service_port' => Utils::Test.new('80 | 8080') do |sb, is|
                                             next true if !mCfg.getServersRunning('store').include?(mHost.to_s)
                                             sb = '8080'
                                             wPort = mCfg.hasOption('zimbra-store', 'HTTPPORT')
                                             next is == wPort if wPort
                                             wProxy = mCfg.getServersRunning('proxy').empty? ? true : mCfg.hasOption('zimbra-store', 'zimbraWebProxy', 'FALSE')
                                             next is == '80' if wProxy
                                             is == sb
                                           end,
             'zimbra_mysql_connector_maxActive' => Utils::Test.new('number, default 100') do |sb, is|
                                                     if Model::Deployment.getServersRunning('store').include?(mHost.to_s)
                                                       is == '100'
                                                     else
                                                       is == 'Unset'
                                                     end
                                                   end, #store only
             'zimbra_mysql_password' => Utils::Test.new('a password') {|sb, is| is.length >= 6},
             'zimbra_server_hostname' => Utils::Test.new('hostname') {|sb, is| is =~ /\bz?qa.*\.com\b/},
             'zimbra_uid' => Utils::Test.new('zimbra user id') {|sb, is| is =~ /\b\d+\b/},
             'zimbra_waitset_initial_sleep_time' => Utils::Test.new('1000') {|sb, is| is == '1000'},
             'zimbra_waitset_nodata_sleep_time' => Utils::Test.new('3000') {|sb, is| is == '3000'},
             'zimbra_zmprov_default_soap_server' => Utils::Test.new('Default soap server for zmprov to connect to') do |sb, is, host|
                                                      #is lc specified in install/upgrade template?
                                                      sb = 'localhost'
                                                      mServer = XPath.first(Model::Deployment.configuration, "//plugin[option[@name='host']='#{mHost.to_s}' and option[@name='cmd']='/opt/zimbra/bin/zmlocalconfig' and contains(option[@name='parms'],'zimbra_zmprov_default_soap_server')]") rescue nil
                                                      isCustomized = mCfg.zimbraCustomized(mHost.to_s, 'zmlocalconfig', 'any', 'zimbra_zmprov_default_soap_server')
                                                      sb = mServer.to_s[/zimbra_zmprov_default_soap_server=([^; ]+)/, 1] if mServer
                                                      is == sb
                                                    end,
             'zimbra_zmprov_default_to_ldap' => Utils::Test.new('true on mailstore nodes; false otherwise') do |sb, is|
                                                  # false on store nodes running service webapp
                                                  if Model::Deployment.getServersRunning('store').include?(mHost.to_s) &&
                                                     (XPath.first(Model::Deployment.configuration, "//host[@name='#{mHost.to_s}']/package[@name='zimbra-store']/option[@name='SERVICEWEBAPP']").text rescue 'yes') == 'yes'
                                                    is == 'false'
                                                  else
                                                    is == 'true'
                                                  end
                                                end,
             'zimbra_zmjava_options' => Utils::Test.new('-Xmx256m -Djava.net.preferIPv4Stack=true') do |sb, is|
                                          sb = '-Xmx256m'
                                          sb += ' -Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2 -Djdk.tls.client.protocols=TLSv1,TLSv1.1,TLSv1.2' if !Utils::isUpgradeFrom('8\.[05]\.')
                                          ip_mode = mCfg.doc.get_elements('//host').select {|w| w.attributes['name'] == mHost.to_str || w.elements['zimbrahost'].attributes['name'] == mHost.to_str}.first.get_elements('option').select {|w| w.attributes['name'] == 'zimbraIPMode'}.first rescue nil
                                          sb += ' -Djava.net.preferIPv4Stack=true' if ip_mode.nil? || ip_mode.text == 'ipv4'
                                          is == sb
                                        end,
             'zimlet_properties_directory' => Utils::Test.new('undefined on upgrades to 6.0.8+') do |sb, is|
                                                sb = 'Unset'
                                                sb = is if Utils.isUpgrade() && BuildParser.instance.targetBuildId =~ /GNR-60([0-7]\D|\d{2})/
                                                is == sb
                                              end,
             'zmconfigd_enable_config_restarts' => Utils::Test.new('enable config restart') do  |sb, is|
                                                       is == 'true'
                                                     end,
             'zmtrainsa_cleanup_host' => Utils::Test.new('true|false') do |sb, is|
                                           if Model::Deployment.getServersRunning('mta').include?(mHost.to_s) #&& mCfg.getServersRunning('store').include?(mHost.to_s)
                                             is =~ /\b(true|false)\b/
                                           else
                                             is == 'Unset'
                                           end
                                         end, #mta only
           }
mandatory.default = Utils::Test.new('Missing, Update test logic') {|sb, is| false}


#
# Setup
#
current.setup = [

]

#
# Execution
#

current.action = [
  v(RunCommand.new("/bin/ls","root","-l", File.join(Command::ZIMBRAPATH,'conf','localconfig.xml'))) do |mcaller, data|
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
    end
    iResult = iResult.strip.split(/[ \t]+/)[0]
    mcaller.pass = data[0] == 0 && iResult =~ /#{Regexp.new(expectedPermissions)}/
      if(not mcaller.pass)
        class << mcaller
          attr :mbadones, true
        end
        mcaller.mbadones = {'localconfig.xml permissions' => {"IS"=>iResult, "SB"=>expectedPermissions.source}}
      end
    #end
  end,

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'ldap_root_password')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    if data[0] == 0
      rootLdapPassword = data[1]
      if(rootLdapPassword =~ /Data\s+:/)
        rootLdapPassword = rootLdapPassword[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      rootLdapPassword.chomp!
    end
    mcaller.pass = data[0] == 0 && rootLdapPassword != 'UNDEFINED'
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ldap_root_password' => {"IS"=>rootLdapPassword, "SB"=>"Defined"}}
    end
  end,

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'zimbra_ldap_password')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    if data[0] == 0
      zimbraLdapPassword = data[1]
      if(zimbraLdapPassword =~ /Data\s+:/)
        zimbraLdapPassword = zimbraLdapPassword[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      zimbraLdapPassword.chomp!
    end
    mcaller.pass = data[0] == 0 && zimbraLdapPassword != 'UNDEFINED' && zimbraLdapPassword != rootLdapPassword
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {'zimbra_ldap_password' => {"IS"=>zimbraLdapPassword, "SB"=>"Defined"}}
      elsif zimbraLdapPassword == 'UNDEFINED'
        mcaller.badones = {'zimbra_ldap_password' => {"IS"=>zimbraLdapPassword, "SB"=>"Defined"}}
      else
        if BuildParser.instance.baseBuildId[/_FRANK(LIN_D\d)?_/].nil?
          if zimbraLdapPassword == rootLdapPassword
            mcaller.badones = {'ldap_root_password != zimbra_ldap_password' => {"IS"=>"#{false}(#{zimbraLdapPassword} == #{rootLdapPassword})", "SB"=>true}}
          end
        else
          if zimbraLdapPassword != rootLdapPassword
            mcaller.badones = {'ldap_root_password == zimbra_ldap_password' => {"IS"=>"#{false}(#{zimbraLdapPassword} != #{rootLdapPassword})", "SB"=>true}}
          end
        end
      end
    end
  end,

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s', '-m nokey', 'localized_client_msgs_directory')) do |mcaller, data|
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    if data[0] == 0
      dir = data[1]
      if(dir =~ /Data\s+:/)
        dir = dir[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      dir.chomp!
    end
    expected = File.join('${mailboxd_directory}', 'webapps', 'zimbra', 'WEB-INF', 'classes', 'messages')
    if dir != expected
      if(Model::TARGETHOST.architecture == 1 || Model::TARGETHOST.architecture == 9 || Model::TARGETHOST.architecture == 39)
        expected = File.join(Command::ZIMBRAPATH, 'mailboxd', 'webapps', 'zimbra', 'WEB-INF', 'classes', 'messages')
      end
    end
    mcaller.pass = data[0] == 0 && dir == expected
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'localized_client_msgs_directory' => {"IS"=>dir, "SB"=>expected}}
    end
  end,

  v(cb("local mailboxd_truststore") do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                             '-s', '-m nokey', 'zimbra_java_home')
    data = mObject.run
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    if data[0] == 0
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      iResult.chomp!
    end
    mObject = RunCommand.new('ls', 'root', File.join(iResult, 'lib/security/cacerts'))
    data = mObject.run
    expected = iResult
    expected = File.join(expected, 'jre') if data[1] =~ /No such file or directory/
    expected = File.join(expected, 'lib/security/cacerts')
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                             '-s', '-m nokey', 'mailboxd_truststore')
    data = mObject.run
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    if data[0] == 0
      store = data[1]
      if(store =~ /Data\s+:/)
        store = store[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      store.chomp!
      [0, [store, expected]]
    else
      [1, store]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1][0] == data[1][1]
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'mailboxd_truststore' => {"IS"=>data[1][0], "SB"=>data[1][1]}}
    end
  end,

  Model::Deployment.getServersRunning("*").map do |crt|
    v(cb("local config defaults") do
      mHost = Model::Host.new(crt)
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER, '-s', mHost)
      mResult = mObject.run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      if mResult[0] == 0
        mResult[1] = Hash[*mResult[1].split(/\n/).select {|w| w =~ /\s+=.*$/}.collect {|w| x = w.strip.split(/\s+=\s*/); x.push("EMPTY") if x.length == 1; x}.flatten]
      end
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER, '-s', '-d', mHost)
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      if iResult[0] == 0
        iResult[1] = Hash[*iResult[1].split(/\n/).select {|w| w =~ /\s+=.*$/}.collect {|w| x = w.strip.split(/\s+=\s*/); x.push("EMPTY") if x.length == 1; x}.flatten]
      end
      mResult[1].keys.each do |k|
        mResult[1].delete_if {|k,v| v == iResult[1][k] && !mandatory.has_key?(k)}
      end
      mandatory.keys.each do |k|
        mResult[1].merge!({k => 'Unset'}) if !mResult[1].has_key?(k)
      end
      mResult[1].keys.each do |k|
        mResult[1].delete_if {|k,v| k.match(/^#{Provision::LCPrefix}_/)}
      end
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && (mandatory.keys + data[1].keys).uniq.select {|k| !mandatory[k].call(mandatory[k].to_str,data[1][k])}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        diffs = {}
        (mandatory.keys + data[1].keys).uniq.select {|k| !mandatory[k].call(mandatory[k].to_str,data[1][k])}.collect do |k|
          sb = ZMLocal.new(mHost, '-s', '-d', k).run
          sb = mandatory[k].to_str if sb == ''
          diffs[k] = {"SB" => sb, "IS" => data[1][k]}
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines")
        mcaller.badones = {crt + ' - local config defaults' => diffs}
      end
    end
  end,

  v(cb("unknown local config test") do
    allLC = []
    knownLC = []
    mObject = ZMLocalconfig.new()
    mResult = mObject.run
    if mResult[0] == 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      allLC = mResult[1].split(/\n/).collect {|w| w.split(/\s+=\s+/)[0]}
    end
    mResult = ZMLocalconfig.new('-d').run
    if mResult[0] == 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      knownLC = mResult[1].split(/\n/).collect {|w| w.split(/\s+=\s+/)[0]}
    end
    deletedLC= ['antispam_mysql_bind_address']
    excludeLC = ['av_notify_domain',
                 'av_notify_user',
                 'mailboxd_server',
                 'postfix_mail_owner',
                 'postfix_setgid_group',
                 'smtp_destination',
                 'smtp_notify',
                 'smtp_source',
                 'snmp_notify',
                 'snmp_trap_host',
                 'zimbra_mysql_connector_maxActive',
                 'zmtrainsa_cleanup_host'
                ]
    excludeLC.push('allow_unauthed_ping') if !(XPath.first(mCfg.doc, "//plugin[option[@name='test']='install/modeset.rb' and option[@name='host']='#{Model::TARGETHOST}']") rescue nil).nil?
    allLC.delete_if {|w| w =~ /^#{Provision::LCPrefix}_/}
    allLC.delete_if {|w| w =~ /allow_modifying_deprecated_attributes/}
    mResult = ZMLocalconfig.new('-d', ((allLC + deletedLC).uniq - knownLC).join(" ")).run
    next mResult if mResult[0] != 0
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    errs = {}
    unknownLC = mResult[1].split(/\n/).collect {|w| w[/.*not a known key\s+'([^']+)/, 1]}
    (deletedLC - unknownLC).each {|w| errs[w] = {"IS" => ZMLocal.new(w).run, "SB" => 'not a known key'}}
    (unknownLC - deletedLC).select {|w| !excludeLC.include? w}.each {|w| errs[w] = {"IS" => ZMLocal.new(w).run, "SB" => 'not a known key'}}
    [mResult[0], errs]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :mbadones, true
      end
      mcaller.mbadones = {'unknown lc test' => data[1]}
    end
  end,

  v(cb("local config defaults") do
    lcdumper = 'DumpLC'
    hasBackup = RunCommand.new('ls', Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'backup', 'zimbrabackup.jar')).run[0] == 0
    hasVoice = RunCommand.new('ls', Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'voice', 'zimbravoice.jar')).run[0] == 0
    hasOOffice = RunCommand.new('ls', Command::ZIMBRAUSER,
                                File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'com_zimbra_oo', 'com_zimbra_oo.jar')).run[0] == 0
    DumpLC = 'import com.zimbra.common.localconfig.LC;\n' +
             (hasBackup ? 'import com.zimbra.cs.backup.BackupLC;\n' : '') +
             (hasVoice ? 'import com.zimbra.cs.voice.VoiceLC;\n' : '') +
             (hasOOffice ? 'import com.zimbra.openoffice.config.OpenOfficeLC;\n' : '') +
             'public class DumpLC {\n' +
             '  public static void main(String [] args) {\n' +
             (hasBackup ? '    BackupLC blc = new BackupLC();\n' : '') +
             (hasVoice ? '    VoiceLC vlc = new VoiceLC();\n' : '') +
             (hasOOffice ? '    OpenOfficeLC olc = new OpenOfficeLC();\n' : '') +
             '    String[] keys = LC.getAllKeys();\n' +
             '    for (int i = 0; i < keys.length; ++i) {\n' +
             '      System.out.println(keys[i] + (new Character((char)124)).toString() + (new Character((char)124)).toString() + LC.get(keys[i]));\n' +
             '    };\n' +
             '  };\n' +
             '}'
    mObject = RunCommand.new('/bin/rm', 'root', '-rf', File::join('', 'tmp', "#{lcdumper}.*"))
    mResult = mObject.run
    mObject = RunCommand.new('echo', Command::ZIMBRAUSER, '-e', "\"#{DumpLC}\" > #{File::join('', 'tmp', lcdumper)}.java")
    mResult = mObject.run
    mObject = RunCommand.new('cd /tmp; javac', Command::ZIMBRAUSER,
                             '-cp',
                             File.join(Command::ZIMBRAPATH, 'lib', 'jars', 'zimbracommon.jar') +
                             ':' + File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'backup', 'zimbrabackup.jar') +
                             ':' + File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'voice', 'zimbravoice.jar') +
                             ':' + File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'com_zimbra_oo', 'com_zimbra_oo.jar'),
                             "#{lcdumper}.java")
    mResult = mObject.run
    mObject = RunCommand.new('zmjava ', Command::ZIMBRAUSER,
                             '-cp', File::join('', 'tmp') + ':' + File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'voice', 'zimbravoice.jar') +
                             ':' + File.join(Command::ZIMBRAPATH, 'lib', 'ext', 'com_zimbra_oo', 'com_zimbra_oo.jar'), lcdumper)
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    expected = Hash[*mResult[1].split(/\n/).select {|w| w =~ /\|\|\S+$/}.collect {|w| w.strip.split(/\|\|/)}.flatten]
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-s -x')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    reality = Hash[*mResult[1].split(/\n/).select {|w| w =~ /=\s+\S+$/}.collect {|w| w.chomp.strip.split(/\s+=\s+/)}.flatten]
    expected.default = 'NODEFAULT'
    reality.default = 'UNDEFINED'
    (reality.keys - expected.keys).each do |k|
      expected[k] = 'UNDEFINED'
    end
    #expected['sb_testme'] = 'foo'
    #reality['is_testme'] = 'blah'
    diffs = (expected.keys + reality.keys).uniq.select {|k| expected[k] != reality[k]}.collect {|k| [k, expected[k], reality[k]]}
    [0, diffs]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {}
      data[1].each { |v| mcaller.badones[v[0]] = {"SB"=>v[1], "IS"=>v[2]}}
    end
  end,

  v(cb("local config consistency") do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                              '-x')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    next mResult if mResult[0] != 0
    except = ['zimbra_mysql_connector_maxActive']
    mResult[1] = mResult[1].split(/\n/).select {|w| w=~ /(\S+)\s+=.*$/}.collect {|w| w[/(\S+)\s+=.*$/, 1]}.select {|w| w =~ /[A-Z]/}.select {|w| !except.include?(w)}
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      if data[0] != 0
        msgs = {'localconfig retrieval' => {"IS" => data[1], "SB" => 'found'}}
      else
        data[1].each {|w| msgs[w] = {"IS" => w, "SB" => w.downcase}}
      end
      mcaller.badones = {'local config consistency' => msgs}
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
