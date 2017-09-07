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

puts "Start " + File.basename($0) + "..."
theConfig = 'zimbraMailURL'
#theConfig = 'zimbraVirusWarnRecipient'
expectedValue = '/zimbra'
res = `su - zimbra -c "zmprov gcf #{theConfig} 2>&1"`
if ($?>>8) != 0
   puts "error zmprov gcf #{theConfig} result: #{res}"
   exitCode += 1
else
   name, isValue = res.chomp().split(": ")
   #puts "n=" + name + ", v=" + isValue
   if isValue.nil? or isValue != expectedValue
      if isValue.nil?
         isValue = 'none'
      end
      puts "error #{theConfig} SB:/zimbra IS:#{isValue}"
      exitCode += 1
   else
      puts "#{theConfig} SB:/zimbra IS:#{isValue}"
   end
end
puts "End " + File.basename($0) + "\n"
exit exitCode
