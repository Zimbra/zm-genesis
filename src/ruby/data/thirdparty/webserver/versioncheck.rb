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
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Webserver version test"

include Action 

patches = [Regexp.new('JETTY-1237 Remember local/remote details of endpoint'),
          ]
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  v(cb("Webserver version") do
    mObject = ConfigParser.new()
    mResult = mObject.run
    storeInstalled = begin
                       mObject.isPackageInstalled('zimbra-store')
                     rescue
                       false
                     end
    next([0, OSL::LegalApproved['jetty']]) if !storeInstalled
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmjava'), Command::ZIMBRAUSER,
                             '-jar', File.join(Command::ZIMBRAPATH, 'mailboxd', 'start.jar'),
                             "-DSTART=#{File.join(Command::ZIMBRAPATH, 'mailboxd')}/etc/start.config", '--module=webapp',
                             '--version')
    mResult = mObject.run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1][/\b(\d+(\.\d+){2}\S+).*server/, 1] == OSL::LegalApproved['jetty']
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
      mcaller.badones = {'Webserver version' => {"IS" => data[1][/\b(\d+(\.\d+){2}\S+)/, 1], "SB" => OSL::LegalApproved['jetty']}}
    end
  end,
  
  v(cb("Webserver patch") do
    mObject = ConfigParser.new()
    mResult = mObject.run
    storeInstalled = begin
                       mObject.isPackageInstalled('zimbra-store')
                     rescue
                       false
                     end
     next([0, patches.collect {|w| w.source}.join(" ")]) if !storeInstalled
    mObject = RunCommand.new('cat', Command::ZIMBRAUSER,
                             File.join(Command::ZIMBRAPATH, 'mailboxd', 'VERSION.txt'))
    mResult = mObject.run
  end) do |mcaller, data|
  puts patches.select {|w| data[1] !~ /#{w}/}
    mcaller.pass = data[0] == 0 && patches.select {|w| data[1] !~ /#{w}/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      existing = patches.collect {|w| data[1][/(#{w})/, 1]}.delete_if {|w| w == nil}
      mcaller.badones = {'Webserver patch' => {"IS" => existing.empty? ? 'Missing' : existing, "SB" => patches}}
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
