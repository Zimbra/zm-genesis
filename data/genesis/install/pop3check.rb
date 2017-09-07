#!/usr/bin/ruby -w
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
require 'rexml/document'
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP3 threads test"

include Action 

name = 'zimbraPop3NumThreads'
expected = '100'


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmprov'),
                            Command::ZIMBRAUSER, '-l', 'gcf', name)) do |mcaller, data|
    iResult = data[1]
    if(iResult =~ /Data\s+:/)
      iResult = iResult[/Data\s+:(.*?)\s*\}/m, 1]
    end
    iResult = iResult[/(#{name}:.*)$/, 1]
    iResult = iResult.split()[-1]
    #iResult = Hash[*iResult.split("\n").compact.select {|w| expected.has_key?(w.strip.split('=')[0])}.collect{|y| y.strip.split('=')}.flatten]
    mcaller.pass = data[0] == 0 && expected == iResult
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {name => {"IS"=>"#{iResult}", "SB"=>"#{expected}"}}
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