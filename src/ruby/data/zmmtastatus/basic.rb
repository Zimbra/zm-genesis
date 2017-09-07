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
# Test zmmtastatus
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
require "action/zmmtastatus"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmtastatus"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [


  v(ZMMtastatus.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("zmmtastatus [-h] [-v] [-d]")\
                                 && data[1].include?("-h	Usage")\
                                 && data[1].include?("-v	verbose output")\
                                 && data[1].include?("-d	debug output"))                                                         
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
