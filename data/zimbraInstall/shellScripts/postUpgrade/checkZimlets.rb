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
# Check that new zimlets are deployed during upgrade and old zimlets are undeployed
#       
# 1. get zimlets from ldap: ldapsearch -H ldap://qa11.liquidsys.com -x -w test123 -D uid=zimbra,cn=admins,cn=zimbra -b cn=zimlets,cn=zimbra objectClass=zimbraZimletEntry cn zimbraZimletIsExtension | grep "cn: "| awk '{print $2}' | sort
#
# 2. get zimlets from webserver: ls /opt/zimbra/<WS>/webapps/service/zimlet
#
# 3. get zimlets and zimlets-network
#
# 4. check 1 == 2 == 3
     

require 'fileutils'
require 'find'

exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

require 'getoptlong'

options = {}

opts = GetoptLong.new(
      [ '--bits', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--machine', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--OS', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--build', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--branch', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--baseBuild', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--targetBuild', GetoptLong::REQUIRED_ARGUMENT ]
    )

opts.each do |opt, arg|
    options[opt.gsub(/--/, "")] = arg
end

puts "Start " + File.basename($0) + "..."

res = `su - zimbra -c "zmlocalconfig ldap_url"`
ldapUrl = res.split(' = ')[1].chomp()
res = `su - zimbra -c "zmlocalconfig -s -m nokey ldap_root_password"`
ldapPass = res.chomp()
res = `/opt/zimbra/bin/ldapsearch -H #{ldapUrl} -x -w #{ldapPass} -D uid=zimbra,cn=admins,cn=zimbra -b cn=zimlets,cn=zimbra objectClass=zimbraZimletEntry cn zimbraZimletIsExtension | grep "cn: " | awk '{print $2}'`
ldapZimlets = res.split("\n")

expectedZimlets = []
Dir.foreach('/opt/zimbra/zimlets/') {
   |zimlet|
   next if zimlet =~ /^\.{1,2}/
   expectedZimlets.push(File.basename(zimlet, ".zip"))
}
begin
   Dir.foreach('/opt/zimbra/zimlets-network/') {
      |zimlet|
      next if zimlet =~ /^\.{1,2}/
      expectedZimlets.push(File.basename(zimlet, ".zip"))
   }
rescue Errno::ENOENT
   if options['targetBuild'] =~ /network/i
      puts "error could not find network zimlets: #{$!}"
      exitCode += 1
   end
end
webserverZimlets = []
Dir.foreach('/opt/zimbra/jetty/webapps/service/zimlet') {
   |zimlet|
   next if zimlet =~ /^\.{1,2}/
   webserverZimlets.push(File.basename(zimlet))
}
webserverOnly = webserverZimlets - expectedZimlets
webserverMissing = expectedZimlets - webserverZimlets
ldapOnly = ldapZimlets - expectedZimlets
ldapMissing = expectedZimlets - ldapZimlets
if ! webserverOnly.empty?
   puts "error zimlets found only in webserver: " + webserverOnly.join(" ")
   exitCode += 1
end
if ! webserverMissing.empty?
   puts "error zimlets missing in webserver: " + webserverMissing.join(" ")
   exitCode += 1
end
if ! ldapOnly.empty?
   puts "error zimlets to be deleted from ldap: " + ldapOnly.join(" ")
   exitCode += 1
end
if ! webserverMissing.empty?
   puts "error zimlets to be deployed in ldap: " + ldapMissing.join(" ")
   exitCode += 1
end

puts "End " + File.basename($0) + "\n"
exit exitCode
