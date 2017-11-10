#!/bin/env ruby
#
# $File: //depot/main/ZimbraQA/data/genesis/zmcleantmp/basiccheck.rb $ 
# $DateTime: 2006/03/22 18:43:54 $
#
# $Revision: #1 $
# $Author: vstamatoiu $
# 
# 2010 Vmware
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"
#require "#{mypath}/install/configparser"
#require "#{mypath}/cluster/rhcs/cluster"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmcleantmp test"

include Action 


def installCronjobs(install = true)
  mCrontab = File.join('/tmp', 'crontab.qa')
  res = nil
  if install
    mCmds = [['crontab', '-u', Command::ZIMBRAUSER, mCrontab]]
  else
    mCmds = [['crontab', '-u', Command::ZIMBRAUSER, '-l', '>', mCrontab],
             ['crontab', '-u', Command::ZIMBRAUSER, '-r']
            ]
  end
  mCmds.each_with_index do |mCmd, i|
    mObject = RunCommand.new(mCmd.shift, 'root', *mCmd)
    res = mObject.run
    break if res[0] != 0
  end 
  res
end

#########################################################################
# MACOSX: to enable at, run this command as root:                       #
# launchctl load -w /System/Library/LaunchDaemons/com.apple.atrun.plist #
#                                                                       #
# SuSEES10: In SuSE you log on as root and start YaST.                  #
#           When the YaST window appears click on the system icon on the#
#           left side of the window. The right side of the window will  #
#           get new icons. Look for the icon labeled "Runlevel Editor". #
#           Click on that and it will start a new window.               #
#           Find atd in the list. Highlight atd and click on the        #
#           "Enable" button. You should see a message indicating whether#
#           it worked or not. If it worked then you can use             #
#           the at command right away.                                  #
#           It will also start the atd whenever you restart the system. #
#########################################################################
def runCronjob(cmd, user)
  mResult = RunCommand.new('echo', user, cmd, '|', 'at', '-q z', 'now').run
  mResult = RunCommand.new('atq', user, '-q z').run
  if(mResult[1] =~ /Data\s+:/)
    mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
  end
  while mResult[1] != nil && !mResult[1].empty? do
    sleep 2
    mResult = RunCommand.new('atq', user, '-q z').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
  end
  mResult
end

###############
# help test: wget -O /tmp/xxx --user vmware --password test123 --ca-certificate==/opt/zimbra/ssl/zimbra/commercial/commercial.crt --no-check-certificate https://qa52.lab.zimbra.com:7071/zimbraAdmin/help/en_US/admin/html/appliance/zap_working_in_the_dashboard_tab.htm
###############

cleanupCmd = nil


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("crontab test") do
    mObject = RunCommand.new('crontab', 'root', '-u', Command::ZIMBRAUSER, '-l')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
    end
    cleanupCmd = mResult[1][Regexp.new(File.join(Command::ZIMBRAPATH, '.*', 'zmcleantmp.*'))]
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   !data[1].split(/\n/).select {|w| Regexp.new("^[^#]+\\s+" + File.join(Command::ZIMBRAPATH, 'libexec', 'zmcleantmp')) =~ w}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"crontab test" => {"IS" => data[1].split(/\n/).select {|w| w =~ /#{Regexp.new(".*zmcleantmp.*")}/}.first || 'Missing',
                                            "SB" => "....zmcleantmp..."}}
    end
  end,
  
  v(cb("zmcleantmp test") do
    mObject = RunCommand.new('date', 'root')
    mResult = mObject.run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    now = DateTime.parse(mResult[1])
    #puts now1 = Date.parse(mResult[1])
    aWeekAgo = now - 9
    mTime = aWeekAgo.strftime("%Y%m%d%H%M")
    installCronjobs(false)
    #touch -t YYMMDDhhmm /opt/zimbra/data/tmp/testcleantmpfile.log
    #touch -t YYMMDDhhmm /opt/zimbra/data/tmp/testdir/testnocleantmpfile.log
    #at now zmcleantmp
    mCmds = [['touch', '-t', mTime, File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'testcleantmpfile.log')],
             ['mkdir', '-p', File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'testdir')],
             ['touch', '-t', mTime, File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'testdir', 'testnocleantmpfile.log')],
             #['echo', cleanupCmd, '|', 'at', 'now'],
            ]
    mCmds.each_with_index do |mCmd, i|
      mObject = RunCommand.new(mCmd.shift, Command::ZIMBRAUSER, *mCmd)
      mResult = mObject.run
      break if mResult[0] != 0
    end
    next mResult if mResult[0] != 0
    mResult = runCronjob(cleanupCmd, Command::ZIMBRAUSER)
    sleep 10
    mResult = RunCommand.new('find', Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRAPATH, 'data', 'tmp'),
                             '-name', 'test*cleantmpfile.log', '-print').run
    #installCronjobs(true)
    mResult
  end) do |mcaller, data|
    mFiles = data[1].split(/\n/).select {|w| Regexp.new(File.join(Command::ZIMBRAPATH, 'data', 'tmp', File::SEPARATOR)) =~ w}
    #expected: /opt/zimbra/data/tmp/testzmcleantmp.log - file not found
    mcaller.pass = data[0] == 0 && mFiles.length == 1 &&
                   Regexp.new(File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'testdir', File::SEPARATOR)) =~ mFiles.first 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {"zmcleantmp test" => {"IS" => "exit code = " + data[0] + ", " + data[1] =~ /Data\s+:/ ? data[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]: data[1],
                           "SB" => 'exit code = 0, success'}}
      else
        mcaller.badones = {"zmcleantmp test" => {"IS" => data[1] =~ /Data\s+:/ ? data[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]: data[1],
                           "SB" => 'file not found - ' + data[1][Regexp.new(File.join(Command::ZIMBRAPATH, 'data', 'tmp', File::SEPARATOR) + '[^/]+.log')]}}
      end
    end
  end,
  
  v(cb("at queue cleanup") do
    mResult = RunCommand.new('atq', Command::ZIMBRAUSER, '-q z').run
    next mResult if mResult[0] != 0 || mResult[1].empty?
    mJobs = mResult[1].split(/\n/).collect {|w| w[/^(\d+)/, 1]}
    RunCommand.new('atrm', Command::ZIMBRAUSER, mJobs.join(' ')).run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end

]
    	

#
# Tear Down
#
current.teardown = [
  RunCommand.new('crontab', 'root', '-u', Command::ZIMBRAUSER, File.join('/tmp', 'crontab.qa')),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 