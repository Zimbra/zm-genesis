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
if options['OS'] =~ /macosx/i
   puts "#{options['OS']} Skipping tmpfs check"
else
   res = `df | grep amavisd`
   if res != ""
      puts "error found amavis tmpfs fstab entry #{res}"
      exitCode += 1
   else
      infile = File.new("/etc/fstab", "r")
      infile.each {
               |line|
               if line =~ /^[^#].*\/opt\/zimbra\/amavis.*tmpfs/
                  line.chomp!
                  puts "error found amavis tmpfs in /etc/fstab: #{line}"
                  exitCode += 1
               end
      }
      infile.close
   end
end
puts "End " + File.basename($0) + "\n"

exit exitCode
