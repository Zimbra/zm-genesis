#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/zimbraInstall/shellScripts/postUpgrade/checkPerditionLogLevel.rb
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check tha perdition log level = q(errors only)
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

perdConf = '/opt/zimbra/conf/perdition.conf.in'
cfgFile = File.open(perdConf, "r")
if cfgFile == nil
   puts "error could not open #{perdConf}"
   exitCode += 1
else
   configuration = cfgFile.readlines()
   for i in 0..configuration.length - 1
      if (configuration[i].strip! == 'C') and (configuration[i + 1].strip! == 'd')
         puts "error #{perdConf}, lines #{i + 1},#{i + 2} log level IS:C,d(debug) SB:q(error)"
         exitCode += 1
      elsif configuration[i] == 'q'
         puts "#{perdConf} log level IS:q(error) SB:q(error)"
	 break
      end
   end
   cfgFile.close
end

puts "End " + File.basename($0) + "\n"

exit exitCode
