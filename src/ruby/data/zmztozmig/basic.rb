#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Vmware Zimbra
#
# Test zmztozmig
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmztozmig"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmztozmig"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMZtozmig.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("usage:")\
								 &&	data[1].include?("zmztozmig -[options]")\
								 &&	data[1].include?("Options details:")\
								 &&	data[1].include?("-v --version                    Prints version")\
								 &&	data[1].include?("-h --help                       Shows help")\
								 &&	data[1].include?("[default file -> /opt/zimbra/conf/zmztozmig.conf]")\
								 &&	data[1].include?("-d --debug                      prints versbose debug messages"))
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
