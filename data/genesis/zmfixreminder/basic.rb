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
# Test zmfixreminder
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
require "action/zmfixreminder"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmfixreminder"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMFixreminder.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 1 && data[1].include?("Purpose: Fix up appointments without reminders by adding reminders based on user preference")\
                                 && data[1].include?("Usage: /opt/zimbra/libexec/zmfixreminder <options>")\
                                 && data[1].include?("-a <email> - fix the named account")\
                                 && data[1].include?("-a all     - fix all accounts on this server")\
                                 && data[1].include?("-o <output directory> - where temp files are created;")\
                                 && data[1].include?("default is current working directory"))                                 
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
