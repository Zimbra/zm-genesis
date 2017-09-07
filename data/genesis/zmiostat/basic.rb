#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Test zmiostat
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/clean"
require "action/csearch" 
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmiostat"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmiostat"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMIostat.new('--help')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("Usage: /opt/zimbra/libexec/zmiostat")\
                                 && data[1].include?("-i --interval=secs     Seconds between reports (default 60)")\
                                 && data[1].include?("-c --cpu=file          Also record cpu statistics to specified file"))                                                                
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
