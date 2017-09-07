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

defaultDomain = "domain10901.com"
res = `su - zimbra -c "/opt/zimbra/bin/zmprov cd #{defaultDomain} 2>&1"`
defaultAcct = 'acctbug10901@' + defaultDomain
puts "Start " + File.basename($0) + "..."
res = `su - zimbra -c "/opt/zimbra/bin/zmprov ca #{defaultAcct} test123 2>&1"`
if res.include? "ERROR"
   puts "error creating account #{defaultAcct}: #{res}"
   exitCode += 1
end
puts "End " + File.basename($0) + "\n"

exit exitCode
