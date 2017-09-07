#!/bin/env ruby
#
# $File$  $ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check all coses have attributes:
#       
#       

require 'getoptlong'

exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

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

puts "Start " + File.basename($0) + "..."

expectedAttrs = {'zimbraPasswordLockoutDuration' => '1h',
                 'zimbraPasswordLockoutEnabled' => 'FALSE',
                 'zimbraPasswordLockoutFailureLifetime' => '1h',
                 'zimbraPasswordLockoutMaxFailures' => '10'
                }
feature = 'zimbraPasswordLockout'
coses = `su - zimbra -c "zmprov gac 2>&1"`
if ($?>>8) != 0
   puts "error executing \"zmprov gac\" exit code:" + ($?>>8).to_s
   if options['logLevel'] == 'debug'
      puts "result = #{coses}"
   end
   exitCode += 1
else
   coses = ['default', 'newCosWithDefaults']
   coses.each {
      |cos|
      cos.chomp!
      res = `su - zimbra -c "zmprov gc #{cos} | grep #{feature} 2>&1"`
      reality = {}
      res.each {
         |line|
         toks = line.chomp().split(": ")
         reality[toks[0]] = toks[1]
      }
      if reality != expectedAttrs
         #print differences
         expectedKeys = expectedAttrs.keys
         realityKeys = reality.keys
         unexpectedKeys = realityKeys - expectedKeys
         commonKeys = realityKeys - unexpectedKeys
         missingKeys = expectedKeys - realityKeys
         commonKeys.each {
            |key|
            if reality[key] != expectedAttrs[key]
               puts "error in #{cos} COS #{key} SB:#{expectedAttrs[key]} IS:#{reality[key]}"
               exitCode += 1
            elsif options['logLevel'] == 'debug'
               puts "#{cos} COS #{key} SB:#{expectedAttrs[key]} IS:#{reality[key]}"
            end
         }
         missingKeys.each {
            |key|
            puts "error in #{cos} COS #{key} SB:#{expectedAttrs[key]} IS:Missing"
            exitCode += 1
         }
         unexpectedKeys.each {
            |key|
            puts "error in #{cos} COS unexpected attribute #{key}"
            exitCode += 1
         }
      end
   }
end

puts "End " + File.basename($0) + "\n"
exit exitCode
