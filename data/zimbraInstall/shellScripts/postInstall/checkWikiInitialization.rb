#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postInstall/checkWikiInitialization.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check whether Wiki Init succeeds



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
   res = file.readlines().select {|line| line[/^\s*Initializing Documents/]}.collect{|w| w.chomp}
   fail = res.select {|w| w[/failed/]}.length != 0
   if fail
      exitCode += 1
      puts "error Wiki: #{res[0]}."
   else
      puts "Wiki: #{res[0]}."
   end
end

puts "End " + File.basename($0) + "\n"

exit exitCode
