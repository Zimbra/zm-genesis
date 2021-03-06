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
# Test zmmyinit
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
require "action/zmmyinit"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmyinit"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [


  v(ZMMyinit.new('--help')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("zmmyinit [--help] [--sql_root_pw <password>] [--mysql_memory_percent 30]")\
                                 && data[1].include?("--sql_root_pw defaults to random password if not specified")\
                                 && data[1].include?("--mysql_memory_percent defaults to 30 percent if not specified"))                                                         
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
