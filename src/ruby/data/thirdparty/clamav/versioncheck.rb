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
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"
require "action/zmlocalconfig"
require 'action/oslicense'
require "#{mypath}/upgrade/pre/provision"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ClamAV version test"

include Action 


cvdInit = File.join(Command::ZIMBRAPATH, 'data','clamav', 'init', 'daily.cvd.init')

mConfig = ConfigParser.new()
mConfig.run

#
# Setup
#
current.setup = [
  
] 

#
# Execution
#

current.action = [       
  
  v(cb("Enable Zimbra Services",300) do
    next [0, 'Skipping - appliance'] if Utils::isAppliance
    if BuildParser.instance.baseBuildId == BuildParser.instance.targetBuildId
      [0, 'Skipping - install only']
    else
      exitCode = 0
      res = ''
      mObject = ZMLocal.new('zimbra_server_hostname')
      server = mObject.run
      next[0, 'Skipping - non cluster only'] if mConfig.isClustered(server)
      mResult = ZMProv.new('gs', server).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      config = mResult[1].chomp
      iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
      eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
      cmd = (Provision::ZServices.keys & iservices).select do |w|
              Provision::ZServices[w] != 'enabled'
            end.collect {|w| ['+zimbraServiceEnabled', w]}.flatten
      if cmd != []
        mResult = ZMProv.new('ms', server, *cmd).run
        if mResult[0] != 0
          exitCode += 1 
          if(mResult[1] =~ /Data\s+:/)
            mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          res += mResult[1] + '\n'
        end
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin', 'zmmtactl'),
                                 Command::ZIMBRAUSER, 'reload')
        mResult = mObject.run
        if mResult[0] != 0
          exitCode += 1 
          if(mResult[1] =~ /Data\s+:/)
            mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          res += mResult[1] + '\n'
        end
      end
      [exitCode, res]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Enable Zimbra Services' => {"IS" => data[1], "SB" => "Success"}}
    end
  end,
  
  mConfig.getServersRunning('mta').map do |x|
    v(cb("ClamAV version",300) do
      #next [0, 'Skipping - clamav not installed'] if !Utils::isAppliance && !mConfig.getServersRunning('mta').include?(ZMLocal.new('zimbra_server_hostname').run)
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRACOMMON,'sbin','clamd'),
                                 'root', '--version', '--config-file=/opt/zimbra/conf/clamd.conf')
      mResult = mObject.run
    end)  do |mcaller, data|
      result = data[1].split(/\n/).select {|w| w =~ /ClamAV/}[0][/ClamAV [^\/]+/].split(/ /)[-1].chomp
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['clamav']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - ClamAV version' => {"IS" => result, "SB" => OSL::LegalApproved['clamav']}}
      end
    end
  end,

  mConfig.getServersRunning('mta').map do |x|
    v(cb("ClamAV milter version",300) do
      #next [0, 'Skipping - clamav not installed'] if !Utils::isAppliance && !mConfig.getServersRunning('mta').include?(ZMLocal.new('zimbra_server_hostname').run)
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRACOMMON,'sbin','clamav-milter'),
                              'root','--version')
      mResult = mObject.run
    end) do |mcaller, data|
      result = data[1].split(/\n/).select {|w| w =~ /clamav-milter/}[0][/clamav-milter [^\/]+/].split(/ /)[-1].chomp
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['clamav']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - clamav-milter' => {"IS" => result, "SB" => OSL::LegalApproved['clamav']}}
      end
    end
  end,

  mConfig.getServersRunning('mta').map do |x|
    v(cb("daily.cvd.init version",300) do
      #next [0, 'Skipping - clamav not installed'] if !Utils::isAppliance && !mConfig.getServersRunning('mta').include?(ZMLocal.new('zimbra_server_hostname').run)
      mObject = RunCommandOn.new(x, File.join('/opt/zimbra/common', 'bin','sigtool'), Command::ZIMBRAUSER, '-i', cvdInit)
      mResult = mObject.run
    end) do |mcaller, data|
      expected = '21466'
      mcaller.pass = data[0] == 0 && data[1][/Version:\s+(\d+)/, 1] == expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        result = data[1][/Version:\s+(\d+)/, 1]
        if result == nil
          if(data[1] =~ /Data\s+:/)
            data[1] = data[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          result = data[1].chomp
        end
        mcaller.badones = {x + " - #{cvdInit} version" => {"IS"=>result, "SB"=>expected}}
      end
    end
  end,
  
  v(cb("Disable Zimbra Services", 300) do
    if BuildParser.instance.baseBuildId == BuildParser.instance.targetBuildId
      [0, 'Skipping - install only']
    else
      exitCode = 0
      res = ''
      mObject = ZMLocal.new('zimbra_server_hostname')
      server = mObject.run
      next[0, 'Skipping - non cluster only'] if mConfig.isClustered(server)
      mResult = ZMProv.new('gs', server).run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
      end
      config = mResult[1].chomp
      iservices = config.split(/\n/).select {|w| w =~ /zimbraServiceInstalled:\s+.*$/}.collect {|w| w[/zimbraServiceInstalled:\s+(.*)\s*$/, 1]}
      eservices = config.split(/\n/).select {|w| w =~ /^zimbraServiceEnabled:\s+.*$/}.collect {|w| w[/zimbraServiceEnabled:\s+(.*)\s*$/, 1]}
      cmd = (Provision::ZServices.keys & iservices).select do |w|
              Provision::ZServices[w] != 'enabled'
            end.collect {|w| ['-zimbraServiceEnabled', w]}.flatten
      if cmd != []
        mResult = ZMProv.new('ms', server, *cmd).run
        if mResult[0] != 0
          exitCode += 1 
          if(mResult[1] =~ /Data\s+:/)
            mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          res += mResult[1] + '\n'
        end
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmmtactl'),
                                 Command::ZIMBRAUSER, 'reload')
        mResult = mObject.run
        if mResult[0] != 0
          exitCode += 1 
          if(mResult[1] =~ /Data\s+:/)
            mResult[1] = mResult[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
          end
          res += mResult[1] + '\n'
        end
      end
      [exitCode, res]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Restore Zimbra Services' => {"IS" => data[1], "SB" => "Success"}}
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
