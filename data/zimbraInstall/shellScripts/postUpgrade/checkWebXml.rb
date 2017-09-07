#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postUpgrade/checkWebXml.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check that web.xml has mime type entries for dmg and tgz files as 
# application/octet-stream
#


exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

require 'getoptlong'
require 'rexml/document'
include REXML

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

res = `su - zimbra -c "zmlocalconfig mailboxd_server"`
if res[/jetty/]
   puts "jetty server configuration, skipping"
   puts "End " + File.basename($0) + "\n"
   exit exitCode
end
expectedTypes = {'dmg' => 'application/octet-stream',
                 'tgz' => 'application/octet-stream'
                }

webXml = '/opt/zimbra/tomcat/conf/web.xml'
file = File.open(webXml, "r")
doc = Document.new file

reality = {}
doc.elements.each("/web-app/mime-mapping") {
   |mimeType|
   extension = mimeType.elements["extension"].text
   type = mimeType.elements["mime-type"].text
   reality[extension] = type
}
expectedTypes.each_key {
   |ext|
   if reality.has_key?(ext)
      if expectedTypes[ext] != reality[ext]
         puts "error extension #{ext} in #{webXml} IS:#{reality[ext]} SB:#{expectedTypes[ext]}"
         exitCode += 1
      else
         puts "extension #{ext} in #{webXml} IS:#{reality[ext]} SB:#{expectedTypes[ext]}"
      end
   else
      puts "error extension #{ext} in #{webXml} IS:Missing SB:#{expectedTypes[ext]}"
      exitCode += 1
   end
}

puts "End " + File.basename($0) + "\n"

exit exitCode
