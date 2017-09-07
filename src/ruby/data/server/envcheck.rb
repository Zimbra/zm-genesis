#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare, Inc.
#
# check zimbra environment

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"  
require "action/runcommand"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zimbra env check test"

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
   
  v(RunCommand.new('export DISPLAY=localhost:10.0', 'root', 
                   '; su - ', Command::ZIMBRAUSER, 
                   '-c',
                   '"printenv DISPLAY"',
                   '; unset DISPLAY')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].split(/\n/).select{|w| w =~ /DISPLAY=localhost:10.0/}.empty?
  end
  
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