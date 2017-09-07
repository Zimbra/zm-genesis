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
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Webserver ownership test"

include Action 

webserver = 'UNDEF'
expected = ['root:root', 'root:wheel']

#
# Setup
#
current.setup = [

] 
#
# Execution
#

current.action = [       
  v(cb("webserver detect") do
    mObject = RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), Command::ZIMBRAUSER,
                             '-m nokey', 'mailboxd_server')
    iResult = mObject.run
    if iResult[1] !~ /Warning: null valued key/
      mResult = iResult[1]
      if(mResult =~ /Data\s+:/)
        mResult = mResult[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      end
    else
      mResult = 'tomcat'
    end
    [iResult[0], mResult.chomp.strip]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'webserver check' => {"IS"=>webserver, "SB"=>"tomcat or jetty"}}
    else
      webserver = data[1]
    end
  end,
  
  v(cb("webserver ownership check") do
    mObject = RunCommand.new("/bin/ls","root","-lLd", "/opt/zimbra/" + webserver)
    mResult = mObject.run
    result = 'error'
    if mResult[0] == 0
      result = mResult[1].split(/\n/).select {|w| w =~ /\/opt\/zimbra\/#{webserver}/}[0][/[drwx\-.+]+\s+\d+\s+\S+\s+\S+/].split(/\s+/).slice(2,2).join(':')
    end
    [mResult[0], result]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && expected.include?(data[1])
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {"#{File.join(Command::ZIMBRAPATH,'bin', webserver)} ownership check" => {"IS"=>data[1], "SB"=>expected.join(" or ")}}
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