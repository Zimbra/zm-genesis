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
# Check that wiki template is reloaded during upgrade
#       
#       

require 'fileutils'

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

res = `su - zimbra -c "mysql -e \\\"select path from volume where name like 'message%'\\\" zimbra"`
path = res.split(' ')[1].chomp() + File::SEPARATOR
puts "path=#{path}." if options['logLevel'] == 'debug'
res = `su - zimbra -c "zmprov gcf zimbraNotebookAccount"`
wikiAccount = res.split(": ")[1].chomp()

res = `su - zimbra -c "mysql -e \\\"show databases like 'mboxgroup%'\\\""`
puts "res=#{res}." if options['logLevel'] == 'debug'

mboxes = []
res.each {
   |mbox|
   mbox.chomp!
   next if mbox !~ /^mboxgroup/
#   res = `su - zimbra -c "mysql -e \\\"select mailbox_id, index_id, mod_metadata, name from mail_item where metadata like '%wiki%'\\\" #{mbox}"`
   res = `su - zimbra -c "mysql -e \\\"select mailbox_id, index_id, mod_metadata, name from mail_item where metadata like '%#{wikiAccount}%'\\\" #{mbox}"`
   puts "#{mbox}=#{res}." if options['logLevel'] == 'debug'
   mboxes += res.split("\n") if res != ''
}

count = 0
mboxes.each {
   |line|
   next if line =~ /^mailbox_id/
   (id, index, meta, name) = line.split(' ')
   t1 = path + '0/' + id + '/msg/0/' + index + '-' + meta + '.msg'
   t2 = '/opt/zimbra/wiki/Template/' + name
   t2 += '.wiki' if name !~ /\.gif$/
   puts "t1=#{t1}, t2=#{t2}." if options['logLevel'] == 'debug'
   count += 1
   begin
      if !FileUtils.cmp(t1, t2)
         puts "error old version of #{name}"
         puts "t1=#{t1}, t2=#{t2}." if options['logLevel'] == 'debug'
         exitCode += 1
      end
   rescue
      puts "error #{$!}"
   end 
}
if count != 0
   puts "Wiki Template updated (#{count} files compared)"
else
   puts "error Wiki Template not found"
   exitCode += 1
end

puts "End " + File.basename($0) + "\n"
exit exitCode
