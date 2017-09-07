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
# Check that proc table exists
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

res = `su - zimbra -c "mysql -e \\\"show tables;\\\" mysql"`
reality = res.split("\n")
found = 0
#puts "res=#{reality.join(" ")}."
reality.each {
   |line|
   if line =~ /^proc$/
      found = 1
      break
   end
}
if found == 0
   puts "error missing mysql table: proc"
   exitCode += 1 
end

puts "End " + File.basename($0) + "\n"
exit exitCode
