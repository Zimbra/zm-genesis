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
# Test Summary Processing
require "yaml"
(resultFilePattern, suite, os, build, branch, type, url) = ARGV
#resultFilePattern = "testsummary.txt"
#suite = "SOAP"
#os = "FC5"
#branch = "main"
#type = "SMOKE"
#build = "20061107020101_FOSS"
#h1 = { "a" => 100, "c" => 70}
#h2 = { "a" => 250 }
#
#h3 = h1.merge(h2) do |key, oldval, newval|
#  oldval + newval
#end
#puts YAML.dump(h3)

#Logging
open('/tmp/report.txt','w') do |mfile|
  mfile.puts `pwd`
  mfile.puts resultFilePattern
  mfile.puts suite
  mfile.puts os
  mfile.puts branch
  mfile.puts type
  mfile.puts build
end

exit if [resultFilePattern, build].any? { |x| x.nil? }
#Get statistic from a file and generate a Hash
def getStat(fileName)
  result = Hash.new(0)
  counter = 0
  while((File.size(fileName) == 0) && (counter < 60)) #wait for sixty seconds; ran into situation where file is open but zero sized
    sleep 1
    counter = counter + 1
  end
  File.open(fileName).each do |line|
    next if (line =~/^#/)
    mArray = line.chomp.split(/=|:/).map {|x| x.upcase} 
    result[mArray.first] = result[mArray.first] + mArray[-1].to_i 
  end
  return result
end

# Generate result file pattern base on input file name
def getFilePattern(filePattern)
  return if filePattern.nil?
  File.split(filePattern).inject do |memo, obj|  
    File.join(memo, obj.split(/\./).join('*.'))
  end
end

begin
  # Tally up the results
  result = Dir.glob(getFilePattern(resultFilePattern)).inject(Hash.new) do |memo, obj|
    memo.merge(getStat(obj)) do |key, oldval, newval|
      oldval.to_i + newval.to_i
    end
  end
  
  if(result.size > 0)
    mBuild, mBit = build.split('_')
    mCommand =  "STAF zqa-tms-stax RESULT RECORD SUITE #{suite} OS #{os} BRANCH #{branch} BITS #{mBit} TYPE #{type} BUILD #{mBuild} "+
      "PASSED #{result['PASSED']} FAILED #{result['FAILED']} ERRORS #{result['ERRORS']}"
    mCommand = mCommand + " URL #{url}" unless url.nil?
    open('/tmp/report.txt','a') do |mfile|
      mfile.puts mCommand 
      mfile.puts `#{mCommand}`
    end
  else
    open('/tmp/report.txt','a') do |mfile|
      mfile.puts "No result"
      mfile.puts mCommand
      mfile.puts YAML.dump(result)  
    end
  end
rescue => e
   open('/tmp/report.txt','a') do |mfile|
      mfile.puts e.backtrace.join("\n")
    end
end
