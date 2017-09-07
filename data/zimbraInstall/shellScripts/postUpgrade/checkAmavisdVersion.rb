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
# Check amavisd version
#

expectedVersion = "2.4.3"



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

exitCode = 0
puts "Start " + File.basename($0) + "..."
cmd = 'perl /opt/zimbra/amavisd/sbin/amavisd -c /opt/zimbra/conf/amavisd.conf -V 2>&1'
res = `su - zimbra -c "#{cmd}"`
#puts "ls=#{res}"
realVersion = "Unknown"
if res =~ /^amavisd-new-.*/
    realVersion = res.split(' ')[0].split('-')[-1]
end
if realVersion == expectedVersion
    puts "amavisd version IS:#{realVersion}"
else
    puts "error amavisd version mismatch IS:#{realVersion} SB:#{expectedVersion}"
    exitCode += 1
end

puts "End " + File.basename($0) + "\n"

exit exitCode
