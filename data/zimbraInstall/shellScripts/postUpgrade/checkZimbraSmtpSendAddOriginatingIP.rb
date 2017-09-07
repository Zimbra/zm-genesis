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
# Check that zimbraSmtpSendAddOriginatingIP = TRUE
#


exitCode = 0

#allNames = ('bits', 'machine', 'OS', 'build', 'branch',
#                'baseBuild', 'targetBuild');

puts "Start " + File.basename($0) + "..."
theConfig = 'zimbraSmtpSendAddOriginatingIP'
expectedValue = 'TRUE'
res = `su - zimbra -c "zmprov gcf #{theConfig} 2>&1"`
if ($?>>8) != 0
   puts "error zmprov gcf #{theConfig} result: #{res}"
   exitCode += 1
else
   name, isValue = res.chomp().split(": ")
   if isValue.nil? or isValue != expectedValue
      if isValue.nil?
         isValue = 'Missing'
      end
      puts "error #{theConfig} SB:#{expectedValue} IS:#{isValue}"
      exitCode += 1
   else
      puts "#{theConfig} SB:#{expectedValue} IS:#{isValue}"
   end
end
puts "End " + File.basename($0) + "\n"
exit exitCode
