#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author: 


#
# 2010 Vmware Zimbra
#
# Test zmcpustat
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
require "action/zmcpustat"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmcpustat"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMCpustat.new('-h')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("Usage: /opt/zimbra/libexec/zmcpustat")\
								 &&	data[1].include?("-i --interval=secs     Seconds between reports (default 60)"))
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
