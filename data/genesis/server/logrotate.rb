#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMware Zimbra
#
# Test case for Bug 52576 - logrotation broken USER GROUP 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "logrotate tests"

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

  v(RunCommand.new('logrotate', 'root', '-v', '-f', File.join('/', 'etc', 'logrotate.conf'))) do |mcaller,data| 
    mcaller.pass = data[0] == 0 && !data[1].include?("unknown user 'USER'") &&
                   data[1].split(/\n/).select {|w| w =~ /(Ignoring \S+ because of bad file mode|error:)/}.empty?
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
