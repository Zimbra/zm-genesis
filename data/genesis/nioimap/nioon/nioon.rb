#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# NIO IMAP setup
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmcontrol"
require "action/zmamavisd"

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "NIO IMAP ON"
 
#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [    
   v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'), 
    Command::ZIMBRAUSER, '-e', 'nio_imap_enabled=true')) do |mcaller, data|
      mcaller.pass = data[0] == 0
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
