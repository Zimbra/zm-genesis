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
# Check openldap version
#


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

#print opts.get(), options['baseBuild']

puts "Start " + File.basename($0) + "..."
expectedVer = "2.3.34"
rex = Regexp.new(expectedVer)
cmd = '/opt/zimbra/openldap/libexec/slapd -V 2>&1'
res = `su - zimbra -c "#{cmd}"`
if (res.index("@\(#\) $OpenLDAP: slapd") != 0)
   res.chomp!
   puts "error command #{cmd} failed, output: #{res}"
   exitCode += 1
else
   res = res.split('\n')
   reality = res[0].split(' ')[3]
   if !rex.match(reality)
      puts "error wrong ldap version IS:#{reality} SB: #{expectedVer}"
      exitCode += 1
   else
      puts "ldap version IS:#{reality}"
   end
end
puts "End " + File.basename($0) + "\n"

exit exitCode
