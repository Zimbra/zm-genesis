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
require "#{mypath}/install/utils"
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Timezone preference test"

include Action 


expected = ''
expectedName = nil
defaultTZ = "America/Los_Angeles"
attrName = "zimbraPrefTimeZoneName"

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(cb("config template check") do
    mObject = RunCommand.new("/bin/cat", 'root', File.join(Command::ZIMBRAPATH, '.uninstall', 'config.xml'))
    mResult = mObject.run
    if Utils::isAppliance
      expected = defaultTZ
      next [0, "Appliance: timezone = #{defaultTZ}"]
    end
    if mResult[0] == 0
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = (mResult[1])[/Data\s+:(.*?)\s*\}/m, 1]
      end
      doc = Document.new mResult[1].slice(mResult[1].index('<?xml version'), mResult[1].index('</plan>') - mResult[1].index('<?xml version') + '</plan>'.length)
      expected = defaultTZ
      doc.elements.each("//option") {
        |option|
        if option.attributes['name'] == attrName
          expected = option.text.chomp.strip
        end
      }
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'time zone pref exit code' => {"IS"=>"#{data[0]}", "SB"=>"0"}}
    end
  end,
 
  v(RunCommand.new("/bin/cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'timezones.ics'))) do |mcaller, data|
    iResult = data[1]
    if data[0] == 0
      if(iResult =~ /Data\s+:/)
        iResult = (iResult)[/Data\s+:(.*?)\s*\}/m, 1]
      end
      tzones = {}
      name = nil
      zalias = []
      iResult.split(/\n/).select {|w| w =~ /.*(TZID|X-ZIMBRA-TZ-ALIAS):.*/}.each do |w|
        if w =~ /TZID/
          tzones[name] = zalias
          name = w[/TZID:\s*(\S+)/,1]
          zalias = []
        else
          zalias.push(w[/X-ZIMBRA-TZ-ALIAS:\s*(.+)$/, 1])
        end
      end
      expectedName = [expected, tzones[expected]].flatten.reject {|w| w == nil}
    end
    mcaller.pass = data[0] == 0 && expectedName != nil
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'time zone name' => {"IS"=>"#{expectedName}", "SB"=>"Found"}}
    end
  end,
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'),
                            Command::ZIMBRAUSER,'gc', 'default')) do |mcaller, data|
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:(.*?)\s+\}/m, 1]
    end
    iResult = iResult[/(zimbraPrefTimeZoneId:.*)$/, 1]
    iResult = iResult.split(/:\s/)[-1]
    iResult.strip!
    mcaller.pass = data[0] == 0 && expectedName.include?(iResult)
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Time zone check' => {"IS"=>iResult, "SB"=>expectedName.join(' or ')}}
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