#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postInstall/checkOSDetection.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check that OS is correctly identified during package install, i.e not as below:
# This platform is RHEL5
# Packages found: zimbra-core-4.5.5_GA_838.RHEL4-20070503171738.i386.rpm
# This may or may not work
#
#
# Install anyway? [N] 



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

suffix = File.open('/opt/zimbra/.update_history', "r").readlines()[0].chomp.split('|')[-1].split('_')[-2,2].join('_')
log = "/tmp/install.out." + suffix
file = File.open(log, "r")
if file == nil
   puts "error could not open #{log}"
   exitCode += 1
else
   found = (1 == 0)
   detected = ""
   file.readlines().each {
      |line|
      if line[/This platform is/]
         found = (1 == 1)
         detected = line.chomp.split(' ')[-1]
      elsif found
         pkg = line.chomp.split(' ')[-1]
         puts "error os/package mismatch - OS=\"#{detected}\" package=\"#{pkg}\"."
         exitCode += 1
         break
      end
   }
end

puts "End " + File.basename($0) + "\n"

exit exitCode
