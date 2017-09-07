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
# Check that /opt/zimbra/tomcat/server/webapps is empty
#       
# 
#
     

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

unwantedDirs = ['/opt/zimbra/tomcat/server/webapps/host-manager',
                '/opt/zimbra/tomcat/server/webapps/manager']

unwantedDirs.each {
   |dir|
   if FileTest.directory?(dir):
      puts "error security hole found directory #{dir} exists"
      exitCode += 1
   end
}

puts "End " + File.basename($0) + "\n"
exit exitCode
