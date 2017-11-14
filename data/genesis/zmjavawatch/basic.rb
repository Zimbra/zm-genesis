#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test zmjavawatch
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmjavawatch"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmjavawatch"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  
  v(ZMJavawatch.new('--help')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("--help                   show usage")\
                                 && data[1].include?("--pid=int                java process id to watch (default:")\
                                 && data[1].include?("--count=int              iterations to run for (default: 4)")\
                                 && data[1].include?("--watch-delay=sec        delay between iterations (default 15s)")\
                                 && data[1].include?("--thread-dump-delay=sec  time to wait for JVM to complete writing")\
                                 && data[1].include?("--thread-dump-file=path  stderr of JVM process where thread dumps"))                                 
  end,
  
  v(cb("Checking zmmailboxdmgr Process using zmjavawatch") do
      host = Model::TARGETHOST
      mObject = RunCommandOnMailbox.new('fuser /opt/zimbra/libexec/zmmailboxdmgr', 'root')
      data = mObject.run
      if data[0] == 0
        process_name = "/opt/zimbra/libexec/zmmailboxdmgr"
        oResult = data[1]
        pid = oResult.split(/\s+/)[-1].chomp.split(/\D+/).first rescue 1 #grab last of pid
        rObject = RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'libexec','zmjavawatch'), Command::ZIMBRAUSER,"--pid=#{pid}", '-count 1')
        rResult = rObject.run
        [rResult[0],rResult[1],pid] 
      else
        data[1] = "Process list(ps command) Command Failed"
        [1,data[1]]       
      end                     
   end) do |mcaller, data, pid|
   mcaller.pass = (data[0] == 0 && data[1].include?("# PID = #{pid}")\
                                   && data[1].include?("# COUNT = 1")\
                                   && data[1].include?("# WATCH DELAY = 15")\
                                   && data[1].include?("# THREAD DUMP DELAY = 1")\
                                   && data[1].include?("# THREAD DUMP FILE = /opt/zimbra/log/zmmailboxd.out"))
   if(not mcaller.pass)
     class << mcaller
       attr :badones, true
     end
     mcaller.badones = {'zmjavawatch command failed:' => {"IS"=>data[1], "SB"=>"Output of zmjavawatch --pid=int --count=int"}}
   end
  end,    
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
