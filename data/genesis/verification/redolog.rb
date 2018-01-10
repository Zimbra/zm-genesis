#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2006 Zimbra
#
# Server file permission check
# This test checks for correctness of the file permissions
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/zmcontrol"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Redolog Verification"
 

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
  v(cb("Redolog check") do
    mObject = Action::RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','zmjava'),'zimbra', 
    'com.zimbra.cs.redolog.util.RedoLogVerify -q redolog').run  
    mObject
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && !data[1].include?('error') 
  end,     
  v(cb("Redolog archive check") do
    mObject = Action::RunCommandOnMailbox.new(File.join(Command::ZIMBRAPATH,'bin','zmjava'),'zimbra', 
    'com.zimbra.cs.redolog.util.RedoLogVerify -q redolog/archive').run  
    mObject
  end) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && !data[1].include?('error') 
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