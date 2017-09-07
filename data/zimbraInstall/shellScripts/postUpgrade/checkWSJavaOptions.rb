#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postUpgrade/checkWSJavaOptions.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Check that webserver java options have -Djava.awt.headless=true
# 
#


exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

require 'getoptlong'
#require 'rexml/document'
#include REXML

options = {}

opts = GetoptLong.new(
      [ '--bits', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--machine', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--OS', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--build', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--branch', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--baseBuild', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--targetBuild', GetoptLong::REQUIRED_ARGUMENT ],
      [ '--logLevel', GetoptLong::REQUIRED_ARGUMENT ]
    )

opts.each do |opt, arg|
    options[opt.gsub(/--/, "")] = arg
end

#print opts.get(), options['baseBuild']

puts "Start " + File.basename($0) + "..."

expectedOptions = ['-Djava.awt.headless=true']
server = `su - zimbra -c "zmlocalconfig mailboxd_server"`.chomp.split(/\s+=\s+/)[-1]
cmd = "zmlocalconfig mailboxd_java_options"
javaOptions = `su - zimbra -c "#{cmd}"`
if ($?>>8) != 0
   puts "error executing \"#{cmd}\" exit code:" + ($?>>8).to_s
   exitCode += 1
else
   expectedOptions.each do
      |option|
      next if javaOptions.include? option
      puts "error #{server} java option IS:Missing SB:#{option}"
      exitCode += 1
   end
end
##
## check that the webserver is running with java.awt.headless=true
##
procid = `cat /opt/zimbra/log/zmmailboxd.pid`.chomp
res = `ps -o command -p #{procid}`
if res.empty?
   puts "error #{server} not running"
   errorCode += 1
else
   res.each do
      |process|
      next if res[/COMMAND/]
      expectedOptions.each do
         |option|
         if !process.include? option
            puts "error #{server} java option IS:Missing SB:#{option}"
            puts "for this process #{process.chomp!}" if options['logLevel'] == 'debug'
            exitCode += 1
         end
      end
   end
end

puts "End " + File.basename($0) + "\n"

exit exitCode
