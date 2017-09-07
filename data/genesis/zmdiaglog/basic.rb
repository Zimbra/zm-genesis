#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#

#
# Test basic zmdiaglog command
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
require "action/command"
require "action/zmprov"
require "action/verify"
require "action/zmdiaglog"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmdiaglog"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
timeNow = Time.now.to_i.to_s
mDir = File.join(Command::ZIMBRAPATH, 'data', 'tmp', name + timeNow)
usage = [Regexp.escape('Usage:'),
         Regexp.escape('zmdiaglog [-h]'),
         Regexp.escape('zmdiaglog [-a | -c] [-d DESTINATION] [-t TIMEOUT] [-j] [-z | -Z]'),
         Regexp.escape('-a    - Do everything: plus collect live JVM heap dump'),
         Regexp.escape('-c    - Use instead of -a to parse heap dump from JVM core dump'),
         Regexp.escape("-d    - Log destination (Default /opt/zimbra/data/tmp)"),
         Regexp.escape('-t    - Timeout in seconds for hanging commands (Default 120)'),
         Regexp.escape('-j    - Also include the output of /opt/zimbra/libexec/zmjavawatch'),
         Regexp.escape('-z    - Archive data collected by zmdiaglog to a bzip2 tar archive and leave data'),
         Regexp.escape('        collection directory intact.'),
         Regexp.escape('-Z    - Archive data collected by zmdiaglog to a bzip2 tar archive AND remove'),
         Regexp.escape('        data collection directory.'),
         Regexp.escape('-h    - Display this help message')
        ]

#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [
  v(ZMDiaglog.new('-h')) do |mcaller,data|
    mcaller.pass = data[0] == 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,
  
  (('0'..'9').to_a + ('a'..'z').to_a + ('A'..'Z').to_a - %w[a c d h j t z Z]).map do |x|
    v(ZMDiaglog.new('-' + x)) do |mcaller,data|
      lines = data[1].split(/\n/).select {|w| w !~ /^\s*$/}
      mcaller.pass = data[0] == 0 &&
                     lines.select {|w| w !~ /#{usage.join('|')}|#{Regexp.escape('Unknown option:')}/}.empty?  
    end
  end,
  
  v(ZMDiaglog.new('-a')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?("ZCS mailboxd pid")
  end,
  
  v(ZMDiaglog.new('-Z', '-d', mDir)) do |mcaller,data|
    mcaller.pass = data[0] == 0 &&
                   !data[1].chomp.split(/\n/).select{|w| w =~ /Archive\s+#{Regexp.new(File.join(mDir, "zmdiaglog-#{Model::TARGETHOST}"))}(\.[\da-f-]+){2}\.tar\.bz2 complete\./}.empty?
  end,
  
  v(RunCommand.new('du', Command::ZIMBRAUSER, '-c', '-h', File.join(mDir, '*.bz2'))) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).last !~ /0\s+total/
  end,
  
=begin
  v(RunCommand.new('du', Command::ZIMBRAUSER, '-c', '-h', mDir)) do |mcaller,data|
    mcaller.pass = data[0] != 0 && data[1].split(/\n/).last =~ /0\s+total/
  end,
  
  v(RunCommand.new('mkdir', 'root', mDir + '1')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(RunCommand.new('chmod', 'root', 'u-w', mDir + '1')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMDiaglog.new('-Z', '-d', mDir + '1')) do |mcaller,data|
    mcaller.pass = data[0] == 0 &&
                   data[1] !~ /^\s+zip warning:\s+/ &&
                   data[1] =~ /^An error occurred creating #{mDir}1\.zip\. Leaving data collection directory intact\.\n/
  end,
  
  v(RunCommand.new('cat', 'root', File.join(mDir+ '1','zmdiag.log'))) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^\s+zip warning:/
  end,
  
  v(RunCommand.new('du', Command::ZIMBRAUSER, '-c', '-h', mDir + '1')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).last !~ /0\s+total/
  end,
=end
  
  # TODO: -z option
  # TODO: zmdiag.log accumulates/appends messages
  
]
#
# Tear Down
#

current.teardown = [

]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
