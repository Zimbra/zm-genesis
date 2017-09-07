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
# Check install steps order
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
require "action/buildparser"
require "#{mypath}/install/configparser"
require "#{mypath}/install/utils"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Install steps test"
expected = ['Starting servers...done.',
            'Notify Zimbra of your installation']
            
include Action
include Model 

 
#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#


current.action = [ 
  v(cb("zimbra notification after server start test") do
    #mObject = ConfigParser.new()
    #mResult = mObject.run
    #servers = mObject.getServersRunning('ldap')
    servers = [Utils::zimbraHostname]
    if Utils::isAppliance
      log = 'APPLIANCE'
      next [0, expected]
    end
    res = {}
    exitCode = 0
    mResult = RunCommand.new("/bin/ls", 'root', '-rt1', '/tmp/install.out.*').run
    iResult = mResult[1]
    if mResult[0] == 0
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      iResult = iResult.split("\n")[-1]
      log = iResult
    end
    servers.each do |host|
      mObject = RunCommandOn.new(host, '/bin/cat', 'root', log)
      mResult = mObject.run
      if mResult[0] != 0
        exitCode += mResult[0]
        res[host] = (tmp = mResult[2].split(/\n/))[0..[4,tmp.length - 1].min]
      else
        res[host] = mResult[1].split(/\n/).select {|w| w =~ /#{Regexp.compile(expected.join('|'))}/}
      end
    end
    [exitCode, res]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1].values.select {|w| w.first !~ /#{Regexp.compile(expected.first)}/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      msgs = {}
      data[1].each_pair do |k, v|
        msgs[k] = {"IS"=>v, "SB"=>expected}
      end
      mcaller.badones = {'zimbra notification after server start test' => msgs}
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