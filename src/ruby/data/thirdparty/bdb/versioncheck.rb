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
current.description = "Bdb version test"

include Action 


expected = '5.2.42'

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [

 v(RunCommand.new(File.join( 'strings ', Command::ZIMBRACOMMON, 'lib/libdb-5.2.so '),
                    Command::ZIMBRAUSER,'| grep 5.2.4')) do |mcaller, data|

  if(data[1] =~ /Data\s+:/)
   data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
#puts data[1]
   end
    result = data[1][/Berkeley DB\s+([^:]+)/, 1]
    result = data[1].chomp if !result
    mcaller.pass = data[0] == 0 && result == expected
   if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'bdb version' => {"IS"=>result, "SB"=>expected}}
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
