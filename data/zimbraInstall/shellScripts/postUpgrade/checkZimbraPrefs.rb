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
# Check 
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
defaultAcct = 'acctbug10901@' + defaultDomain
puts "Start " + File.basename($0) + "..."
expectedPrefs = {'zimbraFeaturePop3DataSourceEnabled'=>'TRUE',
                 'zimbraPrefReadingPaneEnabled'=>'TRUE',
                 'zimbraPrefUseRfc2231'=>'FALSE',
                 'zimbraPrefUseKeyboardShortcuts'=>'TRUE'
                }
res = `su - zimbra -c 'zmprov gc default | grep "zimbra\\\(Pref\\\|Feature\\\)"'`
res.chomp()
reality = {}
res.each() { |pref|
   pref = pref.split(':')
   reality[pref[0]] = pref[1].strip!
}
expectedPrefs.each_key {|pref|
   if reality.has_key?(pref)
      if reality[pref] != expectedPrefs[pref]
         puts "error in default cos #{pref} IS:#{reality[pref]} SB:#{expectedPrefs[pref]}"
         exitCode += 1
      else
         puts "default cos #{pref} IS:#{reality[pref]} SB:#{expectedPrefs[pref]}"
      end
   else
      puts "error in default cos #{pref} IS:Missing SB:#{expectedPrefs[pref]}"
      exitCode += 1
   end
}
puts "End " + File.basename($0) + "\n"

exit exitCode
