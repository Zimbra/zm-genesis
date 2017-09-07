#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# 
# 2010 VMWare
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require 'action/oslicense'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "OpenSSL version test"

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
  
  v(RunCommand.new(File.join(Command::ZIMBRACOMMON, 'bin','openssl'), Command::ZIMBRAUSER,'version')) do |mcaller, data|
    result = data[1][/OpenSSL\s+(\S+)/, 1]
    mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['openssl']
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'openssl version' => {"IS" => result, "SB" => OSL::LegalApproved['openssl']}}
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
