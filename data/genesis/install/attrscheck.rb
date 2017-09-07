#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2009 Zimbra, Inc.
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
require "action/zmlocalconfig"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "#{mypath}/install/attributeparser"
require "action/zmprov"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Global config restrictions test"

include Action 


expected = {'zimbraMtaRestriction' => 2048}

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(cb("Global config restrictions test") do
    mObject = AttributeParser.new('globalConfig')
    mObject.run()
    #TODO: get restrictions instead
    exitCode = 0
    res = {}
    expected.each_pair do |k,v|
      max = "t" * v
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'mcf',
                               "+" + k, max)
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      if data[0] != 0
        exitCode += 1
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'gcf', k)
        data = mObject.run
        iResult = data[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
        end
        res[k] = {"IS" => iResult, "SB" => max}
        next
      end
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'mcf',
                               "-" + k, max)
      data = mObject.run
      max += "t"
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'mcf',
                               "+" + k, max)
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
      end
      if data[0] == 0
        exitCode += 1
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'gcf', k)
        data = mObject.run
        iResult = data[1]
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
        end
        res[k] = {"IS" => iResult, "SB" => "max #{max.length} allowed"}
        mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'mcf',
                               "-" + k, max)
        data = mObject.run
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Global config restrictions test' => data[1]}
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