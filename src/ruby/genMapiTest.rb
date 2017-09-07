#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# Generate MAPI test actions 
# 
require 'yaml'


host = ARGV[0]
branch = ARGV[1]
arch = ARGV[2]

if(branch.nil?)
  puts "branch information required"
  exit 1
end

if(host.nil?)
  puts "host information required"
  exit 1
end

mDirectory = File.join('/opt/qa',branch,'mapivalidator/data/mapivalidator/msi')
if(!File.exists?(mDirectory))
   puts "Directory #{mDirectory} does not exist"
   exit 1
end

mDirectory = File.join('/opt/qa',branch,'mapivalidator/data/mapivalidator/msi')
msiList = Dir.glob(File.join(mDirectory,"*.msi")).map do |fileName|
  'C:'+fileName.sub('/'+branch,'').gsub('/','\\')
end.sort.reverse

restmsi = msiList
puts `/opt/qa/tools/kickoffTest.rb #{host} #{branch} #{arch} Install  >> /opt/qa/tools/#{host}.txt 2>&1`
puts `/opt/qa/tools/kickoffTest.rb #{host} #{branch} #{arch} 'Mapi' >> /opt/qa/tools/#{host}.txt 2>&1`
# Turning off rest of msi test for now..it's halting test run
if(not restmsi.nil?)
   restmsi.each do |x|
      puts `/opt/qa/tools/kickoffTest.rb #{host} #{branch} #{arch} 'Mapi&mapiMsi=#{x}' >> /opt/qa/tools/#{host}.txt 2>&1`
   end
end