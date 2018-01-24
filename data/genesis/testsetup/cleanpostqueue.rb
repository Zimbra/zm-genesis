#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 Zimbra
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov"
require "action/verify"

include Action

current = Model::TestCase.instance()
current.description = "Clean postfix queue" 
 
  

#
# Global variable declaration
#

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [    
     Action::RunCommandOnMta.new(File.join(Command::ZIMBRAPATH, 'postfix', 'sbin', 'postsuper'), 'root', '-d ALL')  
]

#
# Tear Down
#
current.teardown = [     
  
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance, false).run  
end
