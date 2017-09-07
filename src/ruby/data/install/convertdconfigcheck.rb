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
require "action/zmprov"
require "action/buildparser"
require "#{mypath}/install/configparser"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "convertd config check"

include Action 


#
# Setup
#
current.setup = [
   
] 

expected = {'ErrorLog' => '"\|\/opt\/zimbra\/common\/bin\/rotatelogs\s+\/opt\/zimbra\/log\/convertd\.log\.%Y-%m-%d\s+86400"',
           }

configFile = File.join(Command::ZIMBRAPATH, 'convertd', 'conf', 'httpd.conf')

#
# Execution
#


current.action = [
  v(cb("convertd config test") do
    mObject = ConfigParser.new()
    mResult = mObject.run
    hasPackage = begin
                   mObject.isPackageInstalled('zimbra-convertd')
                 rescue
                   true
                 end
    if !hasPackage
      [0, {}]
    else
      mObject = Action::RunCommand.new('/bin/cat', 'root', configFile)
      data = mObject.run
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      res = {}
      if data[0] != 0
        [data[0], iResult]
      else
        expected.keys.collect do |key|
          iResult.split(/\n/).select do |w|
            w =~ /#{Regexp.compile("^#{key}\\s+")}/
          end.select do |w|
            w !~ /#{Regexp.compile("#{expected[key]}")}/
          end.collect do |w|
            res[key] = w[/#{Regexp.compile("^#{key}\\s+(.*)")}/]
          end
        end
        [data[0], res]
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {configFile + ' check' => {}}
      messages = {}
      if data[0] != 0
        messages[configFile] = {"IS" => data[1], "SB" => "get file content succeeded"}
      else
        data[1].each_pair do |key, val|
          messages[key] = {"IS" => val, "SB" => "^#{key}\\s+" + expected[key]}
        end
      end
      mcaller.badones[configFile + ' check'] = messages
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