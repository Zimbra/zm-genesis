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
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "DB integrity test"

include Action 


mysqlPassword = 'UNDEFINED'
(mCfg = ConfigParser.new).run

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
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'),
                       Command::ZIMBRAUSER, 
                       '-s', '--format', 'nokey',
                       'mysql_root_password')) do |mcaller, data|
      data[0] = 1 if data[1] =~ /Warning: null valued key/
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1] #[/Data\s+:(.*?)\s*\}/m, 1]
      end
      mysqlPassword = iResult.chomp
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - mysql_root_password' => {"IS"=>mysqlPassword, "SB"=>"Defined"}}
      end
    end,
    
    v(cb("DB integrity test", 300) do
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRAPATH, 'common','bin','mysqlcheck'), Command::ZIMBRAUSER,
                                 "--defaults-file=" + File.join(Command::ZIMBRAPATH, 'conf', 'my.cnf'),
                                 '-A', '-C', '-s',
                                 '-S', File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'mysql', 'mysql.sock'),
                                 '-u root',
                                 "--password=#{mysqlPassword}")
      mResult = mObject.run
      iResult = mResult[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      [mResult[0], iResult.to_s]
    end) do |mcaller, data|
      excepts = ["mysql.general_log",
                 "Error    : You can't use locks with log tables.",
                 "mysql.slow_log",
                 "Error    : You can't use locks with log tables."
                ]
      mcaller.pass = data[0] == 0 && (data[1] == "" ||
                     RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','mysql'), Command::ZIMBRAUSER,'--version').run[1][/Distrib\s([^,]*).*/, 1] =~ /5\.1\.5[0-5]\b/ && 
                     data[1].split(/\n/).sort == excepts.sort)
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - DB integrity test' => {"IS"=>data[1], "SB"=>'No errors found'}}
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