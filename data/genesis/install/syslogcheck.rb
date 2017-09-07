#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Zimbra
#
# Check that syslog is working
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require 'model'
require 'action/runcommand'
require 'action/verify'
require 'action/block'
require 'date'
require "action/buildparser"



#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "syslog test"

include Action
include Model

mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]
timeNow = Time.now.to_i.to_s
zimbraStart = nil


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#


current.action = [ 
  v(cb("/var/log/zimbra.log test") do
    mResult = RunCommand.new('ls', 'root', '-tr1', File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'),
                             '|', 'tail', '-1',
                             '|', 'xargs', 'head', '-1').run
    if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    zmsetupStart = DateTime.parse(mResult[1])
    mResult = RunCommand.new('ls', 'root', '-tr1', '/var/log/zimbra.log*',
                             '|', 'tail', '-3').run
    if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    mResult = RunCommand.new('zgrep', 'root', "\"Starting services initiated by zmcontrol\"",
                             mResult[1].split(/\n/).join(' '),
                             '|', 'tail', '-1').run
    if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    start = mResult[1].split(/\n/)[-1][/(\/var\/log[^:]+:)?\s*(.*)\s+\S+\s+zimbramon/, 2]
    zimbraStart = zmsetupStart - 1
    if start != nil
      zimbraStart = DateTime.parse(start + ' ' + Time.new().year.to_s)
    end
    [zmsetupStart, zimbraStart]
  end)do | mcaller,data|
     mcaller.pass = data[0] <= data[1]
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'/var/log/zimbra.log test' => {"SB"=>'zimbra start after zmsetup',
                                                        "IS" => "installation started at #{data[0]}, zimbra start at #{data[1]}."}}
    end
  end,
  
  #check that /var/log/messages size != 0
  # du -s /var/log/messages
  # 0 /var/log/messages
  if [ 2, #RHEL4
      11, #RHEL4_64
      26, #RHEL5
      27, #RHEL5_64
      60, #RHEL6_64
      80, #RHEL7_64
     ].include?(Model::TARGETHOST.architecture)
    v(RunCommand.new('du', 'root', '-s', '/var/log/messages')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1] !~ /^\s*0\s+\/var\/log\/messages/
      if not mcaller.pass
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'/var/log/messages size' => {"SB"=>'> 0',
                                                        "IS" => data[0] == 0 ? data[1].split(/\n/).last.split.first : 'no such file'}}
        #repair syslog.conf
        #add the following line after "# Don't log private authentication messages!"
        #*.info;local0.none;local1.none;auth.none;mail.none;authpriv.none;cron.none         /var/log/messages
        mResult = RunCommand.new('sed', 'root', '-i.qa', '-e',
                                 "\"\/log private authentication messages\/ a\\\n" +
                                 "*\.info;local0\.none;local1\.none;auth\.none;mail\.none;authpriv\.none;cron\.none" +
                                 "\t\/var\/log\/messages\"", '/etc/syslog.conf').run
        RunCommand.new('kill', 'root', '-HUP', '`cat /var/run/*syslogd*.pid`').run if mResult[0] == 0
      end
    end
  end,
  
  #RunCommand.new('sort', 'root', File.join('', 'var', 'log', 'messages.1'),
   #              '-o', file1 = File.join('', 'tmp', 'messages' + timeNow)),
  
  
if mArchitecture =~ /UBUNTU/
 RunCommand.new('sort', 'root', File.join('', 'var', 'log', 'messages.1'),
                 '-o', file1 = File.join('', 'tmp', 'messages' + timeNow))
 else
  RunCommand.new('sort', 'root', File.join('', 'var', 'log', 'messages'),
                  '-o', file1 = File.join('', 'tmp', 'messages' + timeNow))

 end,

  
  v(RunCommand.new('du', 'root', file1)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).first.split.first.to_i != 0
  end,
  
  RunCommand.new('sort', 'root', File.join('', 'var', 'log', 'zimbra-stats.log'),
                 '-o', file2 = File.join('', 'tmp', 'zimbra-stats.log' + timeNow)),
  
  v(RunCommand.new('du', 'root', file2)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).first.split.first.to_i != 0
  end,
  
  #TODO - check the files are not empty
  #Assumes that uninstall cleanups zimbra-stats.log
  v(RunCommand.new('comm', 'root', '-12', file1, file2, '|', 'tail', '-5')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (data[1].empty? || zimbraStart > DateTime.parse(data[1].split(/\n/).last[/^\s*(.*)\s+\S+\s+zimbramon/, 1] + ' 2012'))
    if not mcaller.pass
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'duplicated zimbra-stats messages' => {'SB' => 'zimbra messages not found in /var/log/messages',
                                                                'IS' => "#{data[1]}..."}}
    end
  end,
  
  v(RunCommand.new('rm', 'root', '-rf', file1, file2)) do |mcaller, data|
    mcaller.pass = data[0] == 0
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