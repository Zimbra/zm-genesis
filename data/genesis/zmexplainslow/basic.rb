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
# Test zmexplainslow
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
require "action/zmexplainslow"
require "action/zmsoap"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmexplainslow"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMExplainslow.new('--help')) do |mcaller,data|
	mcaller.pass = (data[0] == 0 && data[1].include?("zmexplainslow [slowQueries.csv]")\
								 && data[1].include?("Runs EXPLAIN on SELECT statements in the specified file")\
								 && data[1].include?("-h, --help           Displays this usage message")\
								 && data[1].include?("-i, --ignore=regexp  Ignore any SELECT statements that match the")\
								 && data[1].include?("-u, --user=name      MySQL user name (default: \"zimbra\")")\
								 && data[1].include?("-p, --password=name  MySQL password (default: \"zimbra\")")\
								 && data[1].include?("-d, --database=name  MySQL database (default: \"zimbra\")")\
								 &&	data[1].include?("-m, --mysql=command  MySQL client command name (default: \"mysql\")"))
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
