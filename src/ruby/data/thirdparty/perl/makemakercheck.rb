#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMware
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
current.description = "ExtUtils::MakeMaker version test"

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
  v(RunCommand.new('perl', Command::ZIMBRAUSER,
                   '-e "use ExtUtils::MakeMaker; print \\$INC{\"ExtUtils/MakeMaker.pm\"}"')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /#{Command::ZIMBRAPATH}/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'ExtUtils::MakeMaker version' => {"IS" => data[1], "SB" => "not found in #{File.join(Command::ZIMBRAPATH, '...')}"}}
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
