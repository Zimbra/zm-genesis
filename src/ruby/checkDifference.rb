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
# This program will check if two files are different using chksum call
# This program is intended to be used with find command
# arg0 = original target file name
# arg1 = regex expression to be searched
# arg2 = regex subsitution
# 
# usage example find . -exec <thisprogram> {} before after \;
instring =  File.expand_path(ARGV[0])
before = ARGV[1]
after = ARGV[2]
astring = instring.sub(/#{before}/, after)
#Skip directory
exit if File.directory?(instring)
if(File.exist?(astring))
   chksumOne = `cksum #{instring.chomp}`
   chksumTwo = `cksum #{astring.chomp}`
   if(chksumOne.split[0] != chksumTwo.split[0])
      puts "File #{astring.chomp} #{instring.chomp} differs"
   end
else
   puts "File #{astring.chomp} is missing, orgin #{instring.chomp}"
end