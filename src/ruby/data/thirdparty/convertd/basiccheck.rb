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
require "model/deployment"
require "#{mypath}/cluster/rhcs/cluster"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Convertd test"

include Action 


basicCmd = File.join(Command::ZIMBRAPATH, 'keyview', 'FilterSDK', 'bin', 'filter')
hosts = Model::Deployment.getServersRunning('convertd')
allHosts = Model::Deployment.getAllServers()
cluster = Cluster::ClusterStat.new()
mResult = cluster.run
hosts = hosts - cluster.nodes.keys.select {|w| cluster.nodes[w][Cluster::NodeState] == Cluster::StateStandby}


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("FilterSDK test") do
    res = {}
    exitCode = 0
    allHosts.each do |host|
      if BuildParser.instance.targetBuildId =~ /(FOSS)/i || !hosts.include?(host)
        expected = ".*No such file or directory.*"
      else
        expected = "Usage:\\s+#{basicCmd}\\s+\\[options\\].*"
      end
      mObject = RunCommandOn.new(host, basicCmd, Command::ZIMBRAUSER,'--help', '2>&1')
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if iResult[1][/#{Regexp.new(expected)}/].nil?
        res[host] = [iResult[1], expected]
        exitCode += 1
      end
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
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip()}", "SB"=>v[1]}
      end
      mcaller.badones = {"#{basicCmd} --help test" => msgs}
    end
  end,

  v(cb("keyview version test") do
    res = {}
    exitCode = 0
    allHosts.each do |host|
      if BuildParser.instance.targetBuildId =~ /(FOSS)/i || !hosts.include?(host)
        expected = ".*No such file or directory"
      else
        expected = "version=10.13.0.0"
      end
      mObject = RunCommandOn.new(host, 'grep', Command::ZIMBRAUSER, "\"version=\"",
                                 File.join(Command::ZIMBRAPATH, 'keyview', 'FilterSDK', 'bin', 'formats.ini'), '2>&1')
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if iResult[1][/#{Regexp.new(expected)}(\s+|$)/].nil?
        res[host] = [iResult[1], expected]
        exitCode += 1
      end
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
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip()}", "SB"=>v[1]}
      end
      mcaller.badones = {"keyview version test" => msgs}
    end
  end,

  if !hosts.empty?
    v(RunCommandOn.new(hosts[0], 'find', 'root', Command::ZIMBRAPATH, '-name', 'liboutsidein.so', '-print')) do |mcaller, data|
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mcaller.pass = data[0] == 1 || iResult == nil || iResult == ''
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'liboutsidein.so check' => {"IS"=>iResult, "SB"=>"Missing"}}
      end
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