#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Nginx, IMAP STARTTLS extra untagged response bug#54039"

cap_num = nil #counter for CAPABILITY responses
mimap = Net::IMAP.new(Model::TARGETHOST, *Model::IMAP) 

include Action

#Net::IMAP.debug = true
#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
	v( proxy(mimap.method('send_command'), "capability")) { |mcaller, data|
  	mcaller.pass = (data.class == Net::IMAP::TaggedResponse) 
	# save the current number of CAPABILITY responces
	cap_num = mimap.responses["CAPABILITY"].size
	},

	v( proxy(mimap.method('send_command'), "STARTTLS")) { |mcaller, data|
	mcaller.pass = ((data.class == Net::IMAP::TaggedResponse) &&
	 (cap_num == mimap.responses["CAPABILITY"].size)) # should be the same number
	}
]

#
# Tear Down
#
current.teardown = [      
  proxy(mimap.method('disconnect')),  
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
