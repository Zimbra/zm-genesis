#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 Zimbra
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmprov"
require "action/zmlocalconfig"
require "action/zmamavisd"


include Action

current = Model::TestCase.instance()
current.description = "Set number of consecutive errors allowed in IMAP to infinity" 

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
  # change number of consecutive errors allowed in IMAP and POP3 to infinity
  # for testing purpose only
  # see bug #67663 and bug #51171
  RunCommandOnMailbox.new('zmlocalconfig -e imap_max_consecutive_error=0'),
  RunCommandOnMailbox.new('zmlocalconfig -e pop3_max_consecutive_error=0'),
  ZMMailboxdctl.new("restart"),
  cb("wait") {sleep(5)},
     
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

