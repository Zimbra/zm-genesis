#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMware Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby'))
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
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Altermime version test"

include Action 


(mCfg = ConfigParser.new).run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  mCfg.getServersRunning('mta').map do |x|
    v(RunCommand.new(File.join(Command::ZIMBRACOMMON, 'bin','altermime'),
                     Command::ZIMBRAUSER, '--version', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = (result = data[1][/alterMIME\s+v(\S+)/, 1]) == OSL::LegalApproved['altermime']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - altermime version' => {"IS" => result, "SB" => OSL::LegalApproved['altermime']}}
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