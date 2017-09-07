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

expectedWarning = ["Warning: You are about to upgrade from the Network Edition to the",
                   "Open Source Edition.  This will remove all Network features, including",
                   "Attachment Searching, Zimbra Mobile, Backup/Restore, and support for the ",
                   "Zimbra Connector for Outlook."]

puts "Start " + File.basename($0) + "..."

if options['OS'] =~ /MACOSX/i
   puts "#{options['OS']} build, skipping..."
else
   toks = options['targetBuild'].split('_')
   id = toks[-2] + "_" + toks[-1].split(".")[-2]
   infile = File.new("/tmp/install.out.#{id}", "r")
   found = 0
   infile.each {
                 |line|
                 line.chomp!
                 if line =~ /#{expectedWarning[0]}/
                    found = 1
                    for i in 1..3
                       line = infile.readline
                       if line !~ /#{expectedWarning[i]}/
                          line.chomp!
                          puts "error unexpected Warning: IS:\"#{line}\" SB:\"#{expectedWarning[i]}\""
                          exitCode += 1
                       end
                    end
                    break
                 end
               }
   infile.close

   if (options['baseBuild'].include? "NETWORK") and (options['targetBuild'].include? "FOSS")
      if found == 0
         puts "error FOSS over NETWORK Warning not found"
         exitCode += 1
      end
   else
      if found == 1:
         from = options['baseBuild'].split('_')[-1].split('.')[0]
         to = options['baseBuild'].split('_')[-1].split('.')[0]
         puts "error found FOSS over NETWORK Warning in a #{from}->#{to} upgrade"
         exitCode += 1
      end
   end
end
puts "End " + File.basename($0) + "\n"

exit exitCode
