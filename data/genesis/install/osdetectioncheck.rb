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
require "#{mypath}/install/utils"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "OS detection test"

include Action 


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

expected = 'UNDEF'

current.action = [       
  
  v(cb("OS detection test") do
    next [0, 'UBUNTU8_64'] if Utils::isAppliance
    if BuildParser.instance.targetBuildId == ''
      [1, "Unknown"]
    else
      timestamp = BuildParser.instance.timestamp
      mObject = Action::RunCommand.new("/bin/cat", "root", "/tmp/install.out." + timestamp)
      index = -1
      mResult = if RUBY_VERSION =~ /1\.8\.\d+/
                  require 'iconv'
                  Iconv.new("US-ASCII//TRANSLIT//IGNORE", "UTF8").iconv(mObject.run[1])
                else
                  mObject.run[1].encode('US-ASCII', 'UTF-8', {:invalid => :replace, :undef => :replace, :replace => ''})
                end
      mResult.split(/\n/).each_index do |idx|
        if mResult[idx] =~ /This platform is/
        #if mResult[idx] =~ /Removing deployed webapp/
          index = idx
          break
        end
      end
      if index == -1
        [0, 'Success']
      else
        [1, [mResult[index].split[-1], mResult[index + 1].split[-1]]]
      end
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'OS detection check' => {"IS"=>"OS="+data[1][0]+" package="+data[1][1], "SB"=>"OS and package match"}}
    end
  end,
  
  v(cb("Platform detection test") do
    if Utils::isAppliance
      expected = 'UBUNTU8_64'
    else
      expected = BuildParser.instance.targetBuildId[/zcs_(\S+)_[^_]+_#{BuildParser.instance.timestamp}.*/, 1]
      next [1, "Unknown"] if BuildParser.instance.targetBuildId == ''
    end
    mObject = Action::RunCommand.new(File.join(Command::ZIMBRAPATH, 'libexec', 'get_plat_tag.sh'),
                                     "root")
    index = -1
    #mResult = mObject.run[1].split(/\n/)
    data = mObject.run
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    [data[0], iResult.chomp]
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] == expected
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Platform detection check' => {"IS"=>data[1], "SB"=>expected}}
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