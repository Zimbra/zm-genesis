#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2009 Zimbra
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
require "#{mypath}/cluster/rhcs/cluster"
require "action/oslicense"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "memcached test"

include Action 


(mObject = ConfigParser.new()).run
hosts = mObject.getServersRunning('memcached')
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
  v(cb("memcached version test") do
    res = {}
    exitCode = 0
    hosts.each do |host|
      mObject = RunCommandOn.new(host, File.join(Command::ZIMBRACOMMON, 'bin', 'memcached'), Command::ZIMBRAUSER,'-h')
      iResult = mObject.run
      if(iResult[1] =~ /Data\s+:/)
        iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      if iResult[1][/#{Regexp.new(OSL::LegalApproved['memcached'])}/].nil?
        res[host] = [iResult[1], OSL::LegalApproved['memcached']]
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
        msgs[k] = {"IS"=>"#{v[0].split("\n")[0].strip().split(/\s+/).last}", "SB"=>v[1]}
      end
      mcaller.badones = {"memcached version test" => msgs}
    end
  end,
  
  v(cb("libevent version test") do
    res = {}
    exitCode = 0
    hosts.each do |host|
      mObject = RunCommandOn.new(host, 'strings', Command::ZIMBRAUSER, 
                                 File.join(Command::ZIMBRACOMMON, 'lib', 'libevent-2.0.so.5'),
                                 '|grep stable')
      iResult = mObject.run
      #if(iResult[1] =~ /Data\s+:/)
      #  iResult[1] = iResult[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      #end
      if iResult[0] != 0
        exitCode += 1
        res[host] = ['Not found', OSL::LegalApproved['libevent']]
        next
      end
      
      #if iResult[1][/\s+"#{Regexp.new(OSL::LegalApproved['libevent'])}"/].nil?
      #  res[host] = [iResult[1][/^\s*#define _EVENT_VERSION\s+"(.*)"/, 1], OSL::LegalApproved['libevent']]
      #  exitCode += 1
      #end
      if iResult[1][/#{Regexp.new(OSL::LegalApproved['libevent'])}/].nil?
        res[host] = [iResult[1], OSL::LegalApproved['libevent']]
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
     mcaller.badones = {"libevent version test" => msgs}
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