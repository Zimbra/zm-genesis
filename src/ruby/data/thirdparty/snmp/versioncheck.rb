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
require "#{mypath}/install/configparser"
require 'action/oslicense'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Snmp version test"

include Action 


(mCfg = ConfigParser.new()).run
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  mCfg.getServersRunning('snmp').map do |x|
    v(RunCommand.new('snmptrap', Command::ZIMBRAUSER,'--version', '2>&1',  Model::Host.new(x))) do |mcaller, data|
      result = data[1][/NET-SNMP version:\s+(\S+)/, 1]
      #result = data[1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['net-snmp']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'snmp version' => {"IS"=>result, "SB"=>OSL::LegalApproved['net-snmp']}}
      end
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
