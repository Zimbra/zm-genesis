#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMware Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby'))
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "rsync version test"

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
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'common', 'bin','rsync'),
                   Command::ZIMBRAUSER,'--version')) do |mcaller, data|
    result = data[1][/rsync\s+version\s(\d(\.\d)+)/, 1]
    mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['rsync']
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'rsync version:' => {"IS"=>result, "SB"=>OSL::LegalApproved['rsync']}}
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