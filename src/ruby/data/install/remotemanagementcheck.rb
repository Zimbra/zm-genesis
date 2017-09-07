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
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Remote management config test"

include Action 


expected = {'zimbraRemoteManagementCommand'=>'/opt/zimbra/libexec/zmrcd',
		    'zimbraRemoteManagementPort'=>'22',
		    'zimbraRemoteManagementPrivateKeyPath'=>'/opt/zimbra/.ssh/zimbra_identity',
		    'zimbraRemoteManagementUser'=>'zimbra'
           }
existingServers = ['UNDEF']

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'),
                            Command::ZIMBRAUSER,'gacf')) do |mcaller, data|
    #data[0] = 1 if data[1] =~ /zmprov \[args\] \[cmd\]/
    iResult = data[1]    		 
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    iResult = iResult.split(/\n/).select {|w| w =~ /zimbraRemoteManagement/}.collect {|w| w.split(/:\s+/)}.flatten
    iResult = Hash[*iResult.collect {|w| w.chomp}]
    diffs = []
    if iResult != expected
      iResult.each_key do |key|
        next if iResult[key] == expected[key]
        diffs << key
      end
    end
    mcaller.pass = data[0] == 0 && diffs.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {'zmprov exit code' => {"IS" => data[0], "SB" => 0}}
      else
        mcaller.badones = {'zimbra configuration test' => {}}
        diffs.each do |key|
          mcaller.badones['zimbra configuration test'][key] = {"IS" => iResult[key], "SB" => expected[key]}
        end
      end
    end
  end,
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'),
                            Command::ZIMBRAUSER,'gas')) do |mcaller, data|
    #result = data[1].select {|w| w =~ /DROP DATABASE IF EXISTS/}
    data[0] = 1 if data[1] =~ /Warning: null valued key/
    iResult = data[1]    		 
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    existingServers = iResult.split(/\n/)
    mcaller.pass = data[0] == 0 && !existingServers.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if data[0] != 0
        mcaller.badones = {'zmprov exit code' => {"IS" => data[0], "SB" => 0}}
      else
        mcaller.badones = {'zimbra servers test' => {"IS"=>data[0], "SB"=>"DEFINED"}}
      end
    end
  end,
  
  v(cb("Remote management test") do
    exitCode = 0
    result = {}
    existingServers.each do |server|
      mObject = RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin','zmprov'), Command::ZIMBRAUSER,
                               'gs', server)
      data = mObject.run
      #exitCode = 1 if data[1] =~ /Warning: null valued key/
      exitCode = 1 if data[0] != 0 
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      iResult = iResult.split(/\n/).select {|w| w =~ /zimbraRemoteManagement/}.collect {|w| w.split(/:\s+/)}.flatten
      iResult = Hash[*iResult.collect {|w| w.chomp}]
      if iResult != expected
        result[server] = {}
        iResult.each_key do |key|
          next if iResult[key] == expected[key]
          result[server][key] = {"IS" => iResult[key], "SB" => expected[key]}
        end
      end
    end
    [exitCode, result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] == {}
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Remote management test' => data[1]}
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