#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Sever bin directory test"

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
  
  # Get a list of executables   
  v(cb("Run executables") do
    mObject = Action::RunCommand.new('ls','root', File.join(Command::ZIMBRAPATH,'bin'))
    mResult = begin
    		iResult = mObject.run[1]    		 
    		if(iResult =~ /Data\s+:/)
    			iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
    		end     
    		iResult = iResult.split.compact
		rescue => e
		  puts e
		  'Unknown'
		end
    mResult = mResult.map {|x| File.join(Command::ZIMBRAPATH, 'bin', x.chomp) }.map do |y|   
      #ls for now, running some commands with '-h' trash server bad atm
      whatever =  Action::RunCommand.new('ls','root', '-l', y).run  
      [y, whatever]
    end     
    mResult
  end) do |mcaller, data|
    data = data.select do |x|  
      puts YAML.dump(x) if $DEBUG 
      !x[1][1].include?('-rwxr-xr-x') 
    end 
    mcaller.pass = (data.size == 0)
    if(not mcaller.pass)
        class << mcaller         
          attr :mbadones, true
        end       
        mcaller.mbadones = data
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