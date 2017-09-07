#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Check various system configuration files

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
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "os settings"

include Action 


commonSessionFile = '/etc/pam.d/common-session'
pamLimitsPat = Regexp.new('^session\s+required\s+pam_limits.so')
(mCfg = ConfigParser.new()).run
mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("common-session setting") do
    if mArchitecture != 'UBUNTU10_64'
      puts "Skipping - file #{commonSessionFile} not present"
      next([0, "Skipping - file #{commonSessionFile} not present"])
    end
    mObject = RunCommand.new('ls', 'root', commonSessionFile)
    mResult = mObject.run
    if mResult[0] != 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = (mResult[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      mResult
    else
      mObject = RunCommand.new('cat', 'root',
                               commonSessionFile)
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      [iResult.split(/\n/).select {|w| w =~ /#{pamLimitsPat}/}.length - 1, iResult]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'common-session settings' => {"IS"=>data[1].split(/\n/).select {|w| w !~ /^#.*/}.collect {|w| w.chomp}, "SB"=>"single entry: " + pamLimitsPat.source}}
    else
    end
  end,
  
=begin 
   v(cb("prerequisite packages") do
    mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]
    prereqPackages = {'libexpat1' => ['UBUNTU10_64',
                                      'UBUNTU12_64',
                                      'UBUNTU14_64'
                                     ],
                      'libstdc\+\+(\.so\.)?6?' => [mArchitecture]
                     }
    exitCode = 0
    res = {}
    mResult = RunCommand.new('cd', 'root', '/opt/zimbra/libexec/installer; source util/utilfunc.sh; source util/globals.sh; getPlatformVars; echo $PREREQ_PACKAGES $PREREQ_LIBS').run
    prereqPackages.each_pair do |pkg, os|
      next if os.include?(mArchitecture) && mResult[1] =~ /[\s\/]+#{pkg}\s/ ||
              !os.include?(mArchitecture) && mResult[1] !~ /[\s\/]+#{pkg}\s/
      mResult[1].chomp!
      exitCode += 1
      res[Model::TARGETHOST.to_str] = [mResult[1], (os.include?(mArchitecture) ? '' : 'no ') + pkg]
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair do |k, v|
        msgs[k] = {"IS"=>v[0], "SB"=>v[1]}
      end
      mcaller.badones = {"checked prerequisite packages" => msgs}
    else
    end
  end,
    
=end
  
  if ['UBUNTU10_64', 'UBUNTU12_64'].include?(mArchitecture) && !Utils.isUpgradeFrom('(7\.2\.\d|8\.0\.[0-3])')
  [
    mCfg.getServersRunning('*').map do |x|
      v(cb("zimbra UID/GID test") do
        mResult = RunCommand.new('cat', 'root', '/etc/login.defs', Encoding::UTF_8, h = Model::Host.new(x)).run
        next mResult if mResult[0] != 0
        mUidMin = mResult[1][/SYS_UID_MIN\s+(\d+)/, 1]
        mUidMax = mResult[1][/SYS_UID_MAX\s+(\d+)/, 1]
        mGidMin = mResult[1][/SYS_GID_MIN\s+(\d+)/, 1]
        mGidMax = mResult[1][/SYS_GID_MAX\s+(\d+)/, 1]
        mResult = RunCommand.new('id', Command::ZIMBRAUSER, h).run
        next mResult if mResult[0] != 0
        mUid = mResult[1][/uid=(\d+)/, 1]
        mGid = mResult[1][/gid=(\d+)/, 1]
        next [1, "zimbra UID=#{mUid} out of system range #{mUidMin}..#{mUidMax}"] unless (mUidMin.to_i..mUidMax.to_i) === mUid.to_i
        next [1, "zimbra UGID=#{mGid} out of system range #{mGidMin}..#{mGidMax}"] unless (mGidMin.to_i..mGidMax.to_i) === mGid.to_i
        [0, "zimbra UID/GID within system range #{mUidMin}..#{mUidMax} and #{mGidMin}..#{mGidMax}"]
      end) do |mcaller, data|
        mcaller.pass = data[0] == 0
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.suppressDump("Suppress dump")
          mcaller.badones = {x + " - zimbra UID/GID test" => {"IS" => data[1], "SB" => 'zimbra UID/GID within system ranges'}}
        end
      end
    end
  ]
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