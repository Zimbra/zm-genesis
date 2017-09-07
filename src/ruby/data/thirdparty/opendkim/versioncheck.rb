#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2013 VMware
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
require 'action/oslicense'
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "OpenDKIM version test"

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
  [
    v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'sbin','opendkim'), Command::ZIMBRAUSER,'-V', Model::Host.new(x))) do |mcaller, data|
      result = data[1][/OpenDKIM Filter v(\S+)/, 1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['opendkim']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - opendkim version' => {"IS" => result, "SB" => OSL::LegalApproved['opendkim']}}
      end
    end,
  ]
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

