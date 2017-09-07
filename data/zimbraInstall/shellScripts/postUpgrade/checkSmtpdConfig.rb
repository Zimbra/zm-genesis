#!/bin/env ruby

# $File$
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Check smtpd default config:
#  smtpd_use_tls=yes
#  smtpd_tls_wrappermode=yes
#  smtpd_sasl_auth_enable=yes


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
exitCode = 0
paramToCheck = {'smtpd_use_tls' => 'yes',
#                'smtpd_tls_wrappermode' => 'yes',
                'smtpd_sasl_auth_enable' => 'yes'}

paramToCheck.each_key {
   |crtParam|
   cmd = 'postconf #{crtParam}'
   res = `su - zimbra -c "postconf #{crtParam} 2>&1"`
   if ($?>>8) != 0
      puts "error executing postconf, exit code #{res}"
      exitCode += 1
   else
      if paramToCheck[crtParam] != res.split('=')[1].strip()
         puts"error smtp config #{crtParam} IS:#{res.split('=')[1].strip()} SB:#{paramToCheck[crtParam]}"
         exitCode += 1
      else
         puts"smtp config #{crtParam} IS:#{res.split('=')[1].strip()} SB:#{paramToCheck[crtParam]}"
      end
   end
}

if exitCode == 0
   res = `su - zimbra -c "zmlocalconfig zimbra_server_hostname"`
   host = res.split('=')[1].strip()
   cmd = "openssl s_client -connect #{host}:465 -quiet 2>&1"
   res = `echo quit | #{cmd}`
   if ($?>>8) != 0
      puts "error executing #{cmd}, exit code #{res}"
      exitCode += 1
   else
      #puts "res=#{res}."
      lines = res.split("\n")
      found = 0
      lines.each {
         |line|
         if line =~ /O=Zimbra Collaboration Suite\/CN=#{host}/
            puts "openssl certificate found #{line}."
            found = 1
            break
         end
      }
      if found == 0
         puts "error openssl certificate not found, output: #{res}"
         exitCode += 1
      end
   end
end

puts "End " + File.basename($0) + "\n"
exit exitCode


# openssl s_client -connect qa14.liquidsys.com:465 -quiet
#connect: Connection refused
#connect:errno=29
# echo $?
#1
