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
current.description = "rrdtool version test"

include Action 


rrdtool_expected = '1.2.30'
libpng_expected = '1.6.23'
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'/bin','rrdtool'),
                            Command::ZIMBRAUSER,'info')) do |mcaller, data|
      result = data[1] 
      mcaller.pass = data[0] == 0 && result.include?(rrdtool_expected)
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'rrdtool version' => {"IS"=>result[/RRDtool\s+([^\s]*).*$/,1], "SB"=>rrdtool_expected}}
    end
  end,
  
  v(RunCommand.new('strings', Command::ZIMBRAUSER,
                   File.join(Command::ZIMBRACOMMON,'lib', 'libpng16.so.16.23.0'))) do |mcaller, data|
      result = data[1][/^libpng\s+version\s(\d+(\.\d+)+)/, 1]
      mcaller.pass = data[0] == 0 && result == libpng_expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'Libpng version' => {"IS"=>result, "SB"=>libpng_expected}}
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
