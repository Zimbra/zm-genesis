#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2014 Zimbra, Inc.
#
# Test zmjava
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/command"
require "action/verify"
require "action/runcommand"
require "model"

include Action 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmjava"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zmjava'), Command::ZIMBRAUSER, '-h')) do |mcaller,data|
  	mcaller.pass = data[0] == 0 && data[1].include?("Usage: java [-options] class [args...]")
  end,
  
  v(RunCommand.new('bash', Command::ZIMBRAUSER, '-x', File.join(Command::ZIMBRAPATH, 'bin', 'zmjava'), '-version')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && (cmd = data[1].split(/\n/).select {|w| w =~ /^\+ exec .*/}).size == 1 &&
                   (['-Dhttps.protocols=TLSv1,TLSv1.1,TLSv1.2', '-Djdk.tls.client.protocols=TLSv1,TLSv1.1,TLSv1.2'] - cmd.first.split).empty?
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
