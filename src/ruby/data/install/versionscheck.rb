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
require "action/zmprov"
require "action/zmsoap"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Versions test"

include Action 


dbVersions = {'db.version' => 'UNDEF',
              'backup.version' => 'UNDEF',
              'index.version' => 'UNDEF',
              'redolog.version' => 'UNDEF'}
isFoss = false
expectedVersions = {}
(mCfg = ConfigParser.new).run
javaHome = ZMLocalconfig.new('-m', 'nokey', 'zimbra_java_home').run[1].chomp
soapServer = ZMProv.new('gas', 'mailbox').run[1].split(/\n/).first

expected = {
            'foo'      => {'approved' => '8.0.0',
                          'proc' => Proc.new() do |ar|
                                      ver = RunCommand.new(File.join(javaHome, 'bin', 'java'), 'root', '-jar', ar).run
                                      ver[1][/Implementation-Version:\s+(.*)$/, 1]
                                    end
                          },
            }
expected.default = {'approved' => ZMSoap.new('-z', '-t', 'admin', '-u', "https://#{soapServer}:7071/service/admin/soap", 'GetVersionInfoRequest').run[1][/\bversion=\W(.*)\W(NETWORK|FOSS)/, 1],
                    'proc' => Proc.new() do |ar|
                                mResult = RunCommand.new(File.join(javaHome, 'bin', 'java'), 'root', '-jar', ar).run
                                ver = mResult[1][/Implementation-Version:\s+(.*)$/, 1]
                                ver.nil? ? 'NOT FOUND' : ver
                              end
                   }
expected['com_zimbra_oo.jar'] = expected.default
ignore = ['com_zimbra_']

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mCfg.getServersRunning('store').map do |x|
  [
  v(cb("DB config versions") do
    isFoss = true if BuildParser.instance.targetBuildId =~ /FOSS/i
    mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','mysql'), Command::ZIMBRAUSER,
                               '--database=zimbra', '--skip-column-names',
                               '--execute="select name, value from config"')
    mResult = mObject.run
    iResult = mResult[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:(.*?)\s*\}/m, 1]
    end
    #iResult = iResult.split()[-1]
    iResult = Hash[*iResult.split("\n").compact.select {|w| w =~ /version/}.collect{|y| y.strip.split()}.flatten]
    iResult.each_key do |key|
      dbVersions[key] = iResult[key]
    end
    [mResult[0], iResult]
  end) do |mcaller, data|
    diffs = {}
    netOnlyKey = 'backup.version'
    if isFoss
      #diffs[netOnlyKey] = {"IS" => dbVersions[netOnlyKey], "SB" => 'NOT FOUND'} if data[1].has_key?(netOnlyKey)
      dbVersions.delete(netOnlyKey)
    end
    (dbVersions.keys - data[1].keys).each do |key|
      diffs[key] = {"IS" => dbVersions[key], "SB" => 'DEFINED'}
    end
    mcaller.pass = data[0] == 0 && diffs.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {x + ' - mysql config table test' => diffs}
    end
  end,
  
  v(cb("Config versions test") do
    mResult = RunCommandOn.new(x, 'rm', 'root', '-rf', '/tmp/*.sql').run
    next([mResult[0], mResult[1] =~ /Data\s+:/ ? mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]: mResult[1]]) unless mResult[0] == 0
    mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmjava'), Command::ZIMBRAUSER,
                               '-cp', File.join(Command::ZIMBRAPATH, 'lib', 'jars', 'zimbrastore.jar'),
                               'com.zimbra.cs.db.MySQL',
                               '-o', '/tmp')
    mResult = mObject.run
    iResult = mResult[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    if mResult[0] != 0
      [mResult[0], iResult]
    else
      mObject = Action::RunCommandOn.new(x, "/bin/cat", "root", File::join('/tmp/', 'versions-init.sql'))
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      if mResult[0] != 0
        [mResult[0], iResult]
      else
        expectedVersions = Hash[*iResult.split(/\n/).select do |w|
          w =~ /\.version.*$/
        end.collect do
          |y| y[/\s*\((.*)\)/, 1].split(',')[0,2]
        end.flatten.collect { |w| w.strip.gsub("'", '')}]
        #[mResult[0], iResult]
        #expectedVersions['db.version'] = '44'
        [0, expectedVersions]
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && (expectedVersions.keys - dbVersions.keys).empty? &&
                   expectedVersions.keys.select {|w| expectedVersions[w] != dbVersions[w]}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {x + ' - Config versions test' => {}}
      if data[0] != 0
        mcaller.badones[x + ' - Config versions test'] = {"IS"=>"exit code = #{data[0]} (#{data[1]})", "SB"=>'exit code = 0'}
      else
        expectedVersions.keys.select {|w| expectedVersions[w] != dbVersions[w]}.each do |key|
          mcaller.badones[x + ' - Config versions test'][key] = {"IS"=>dbVersions[key], "SB"=>expectedVersions[key]}
        end
      end
    end
  end,
  ]
  end,

  if !Utils::upgradeHistory.last =~ /8\.5\.\d+/
  [
    (RunCommand.new('find', 'root', Command::ZIMBRAPATH, '-name', "\"*.jar\"", 
                    "-a ! -path \"\/opt\/zimbra\/jetty*\"",
                    "-a ! -path \"\/opt\/zimbra\/jdk*\"",
                    "-a ! -path \"\/opt\/zimbra\/keyview-*\"",
                    '-print').run[1].split(/\n/).select {|w| w !~ /\/opt\/zimbra\/lib\/jars/ || w =~ /\/opt\/zimbra\/lib\/jars\/.*zimbra*/}).compact.map do |jar|
      v(cb("jar test") do
        keys = expected.keys.select {|k| File.basename(jar) =~ /#{k}/}
        keys = [jar] if keys.empty?
        if keys.length != 1
          next {jar => {'SB' => 'single regexp match', 'IS' => "[#{keys.join(', ')}]"}}
        else
          key = keys.first
        end
        if (found = expected[key]['proc'].call(jar)) != expected[key]['approved']
          next {jar => {'SB' => expected[key]['approved'], 'IS' => found}}
        end
        {}
      end) do |mcaller, data|
        mcaller.pass = data.empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = data
        end
      end
    end
  ]
  end,
  
  mCfg.getServersRunning('*').map do |x|
  [
    v(RunCommand.new('find', 'root', File.join(Command::ZIMBRAPATH, 'lib', 'ext'), "-name", "\"com_zimbra_oo.jar\"", '-print', Model::Host.new(x))) do |mcaller, data|
      expected = 'com_zimbra_oo.jar'
      expected = '' unless BuildParser.instance.targetBuildId =~ /NETWORK/i && mCfg.getServersRunning('store').include?(x)
      mcaller.pass = data[0] == 0 && File.basename(data[1].chomp) == expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'com_zimbra_oo.jar' => {"IS" => data[1], "SB" => expected.empty? ? 'Missing' : 'Found'}}
      end
    end,
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