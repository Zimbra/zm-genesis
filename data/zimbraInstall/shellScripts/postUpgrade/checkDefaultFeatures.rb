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
# Check features :
#       zimbraFeatureIdentitiesEnabled: TRUE
#       zimbraFeatureMobileSyncEnabled: preserved or FALSE


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

expectedFeatures = {
                    'MobileSyncEnabled'=> {'range' => ['Missing', 'TRUE', 'FALSE'],
                                           'behavior' => 'INHERIT or FALSE',
                                           'skip' => '20060922120101'},
                    'IdentitiesEnabled'=> {'range' => ['Missing', 'TRUE', 'FALSE'],
                                           'behavior' => 'TRUE',
                                           'skip' => '20061215020101'}
                   }
prefix = 'zimbraFeature'
rex = prefix
rex += '\(' + expectedFeatures.keys.join('\|') + '\)'
coses = `su - zimbra -c 'zmprov gac | grep -i "#{rex}" 2>&1'`

expectedFeatures.each_key {
   |key|
   coses = `su - zimbra -c 'zmprov gac | grep -i "#{key}" 2>&1'`
   coses.each {
      |cos|
      cos.chomp!
      res = `su - zimbra -c "zmprov gc #{cos} | grep zimbraNotes 2>&1"`
      if ($?>>8) != 0
         puts "error executing \"zmprov gc #{cos} | grep zimbraNotes\" exit code:" + ($?>>8).to_s
         exitCode += 1
         puts "End " + File.basename($0) + "\n"
         exit exitCode
      end
      notes = res.gsub("zimbraNotes: ", "").chomp!
      reality = `su - zimbra -c 'zmprov gc #{cos} | grep "#{prefix}#{key}" 2>&1'`
      reality.chomp!
      reality = "#{prefix}#{key}: Missing" if reality == ''
#      reality = notes if options['baseBuild'].split('_')[-2] > expectedFeatures[key]['skip']
      reality.gsub!(prefix, "")
      toks = reality.split(': ')
      if !notes.include? reality
         if options['baseBuild'].split('_')[-2] <= expectedFeatures[key]['skip']
            puts "error in #{cos} cos #{prefix}#{key} SB:#{expectedFeatures[key]['behavior']} IS:#{toks[1]}."
            exitCode += 1
         else
            puts "#{cos} cos feature #{prefix}#{key} SB:#{expectedFeatures[key]['behavior']} IS:#{toks[1]}."
         end
      else
         puts "#{cos} cos feature #{prefix}#{key} SB:#{expectedFeatures[key]['behavior']} IS:#{toks[1]}."
      end
   }
}

puts "End " + File.basename($0) + "\n"
exit exitCode
