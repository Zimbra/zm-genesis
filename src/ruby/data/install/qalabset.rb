#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 Zimbra
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "QA lab settings"

include Action 

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("clamav proxy settings", 300) do
    mResult = [1, "UNDEFINED"]
    (mObject = ConfigParser.new()).run
    hosts = mObject.getServersRunning('mta')
    hosts = [Utils::zimbraHostname] if Utils::isAppliance
    hosts.each do |h|
      mObject = RunCommandOn.new(h, 'sed', Command::ZIMBRAUSER,
                                 '-i.qalab',
                                 ' -e', "\"s\/\\\(\\s*HTTPProxyServer.*$\\\)\/#\\\\1\/\"",
                                 ' -e', "\"s\/\\\(\\s*HTTPProxyPort.*$\\\)\/#\\\\1\/\"",
                                 File.join(Command::ZIMBRAPATH, 'conf', 'freshclam.conf.in'))
      mResult = mObject.run
      break if mResult[0] != 0
      mObject = RunCommandOn.new(h, 'printf', 'root', '\\\n%s\\\n%s', "\"HTTPProxyServer proxy.vmware.com\"", "\"HTTPProxyPort 3128\" >> #{File.join(Command::ZIMBRAPATH, 'conf', 'freshclam.conf.in')}")
      mResult = mObject.run
      break if mResult[0] != 0
      mObject = RunCommandOn.new(h, File.join(Command::ZIMBRAPATH, 'bin', 'zmclamdctl'), Command::ZIMBRAUSER, 'restart')
      mResult = mObject.run
      break if mResult[0] != 0
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'clamav proxy settings' => {"IS"=>data[1] =~ /Data\s+:/ ? data[1][/Data\s+:\s*([^\s}].*?)\s*\}/m, 1] : data[1],
                                                     "SB"=>"Success"}}
    else
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