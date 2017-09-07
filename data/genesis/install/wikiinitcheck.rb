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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Document initialization test"

include Action 


expected = '5.0.33'
@suffix = "notdef"
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("Document initialization check") do
    mObject = RunCommand.new("/bin/cat", "root", "/opt/zimbra/.update_history")
    mResult = mObject.run[1]
    timestamp = begin
      iResult = mObject.run[1]    		 
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
      end     
    	iResult = iResult.split.compact[0].split('|').slice(-1)[/\d{14}.*/]
	  rescue => e
	    puts e
		  'Unknown'
	end
    mObject = Action::RunCommand.new("/bin/cat", "root", "/tmp/install.out." + timestamp)
    mResult = if RUBY_VERSION =~ /1\.8\.\d+/
                  require 'iconv'
                  Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(mObject.run[1])
                else
                  mObject.run[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''})
                end
    index = -1
    mResult.split(/\n/).each_index do |idx|
      if mResult[idx] =~ /^\s*(Initializing Documents|Upgrading Document templates)\.{3}[Dd]one/
        index = idx
        break
      end
    end
    if index == -1
      [1, 'Documents not initialized']
    else
      [0, mResult[index]]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1] == 'Documents not initialized'
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Document initialization check' => {"IS"=>data[1], "SB"=>"Missing"}}
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