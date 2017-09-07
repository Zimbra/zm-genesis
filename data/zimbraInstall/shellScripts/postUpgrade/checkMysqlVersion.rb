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
# Check zimbraMailURL = /zimbra
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
expectedVer = "5.0.33"
rex = Regexp.new(expectedVer)
cmd = 'mysql --version 2>&1'
res = `su - zimbra -c "#{cmd}"`
res.chomp!
if ($?>>8) != 0
   puts "error command #{cmd} failed: #{res}"
   exitCode += 1
else
   reality = res.split(' ')[4].gsub(',','')
   if !rex.match(reality)
      puts "error wrong mysql version IS:#{reality} SB: #{expectedVer}"
      exitCode += 1
   else
      puts "mysql version IS:#{reality}"
   end
end
puts "End " + File.basename($0) + "\n"

exit exitCode
