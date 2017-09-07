#!/bin/env ruby
#
puts "Syncing"
$stdout.flush
branches = %w(HELIX GNR main)
branches.each do |branch|
   puts "working on %s"%branch
   $stdout.flush
puts `mv /opt/qa/#{branch}/synclient /opt/qa/#{branch}/synclient.old`
   ENV['PATH'] = '/usr/local/staf/bin:'+ENV['PATH']
   ENV['LD_LIBRARY_PATH'] = '/usr/local/lib:/usr/lib:/lib:/usr/local/staf/lib'
   ENV['CLASSPATH'] = '/usr/local/staf/lib/JSTAF.jar'
   ENV['STAFCONVDIR'] = '/usr/local/staf/codepage'
   ENV['STAFCODEPAGE'] = 'LATIN_1'
   command = 'wget -r http://zqa-105.eng.vmware.com/builds/%s/latest/ -P /opt/qa/%s/synclient --no-proxy --level=0 - --waitretry=1 --tries=1 -q -nH -np -R index.html --cut-dirs=3'%[branch, branch]
   puts command
   puts `#{command}`

   
   if(File.exist?("/opt/qa/#{branch}/synclient"))
     puts `/bin/rm -r -f /opt/qa/#{branch}/synclient.old`
   else
     puts `mv /opt/qa/#{branch}/synclient.old /opt/qa/#{branch}/synclient`
   end
end
