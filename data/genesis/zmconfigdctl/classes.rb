#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author: vstamatoiu
#
# 2012 VMWare
#
# Test *ython classes test
#
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
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmconfigdctl python classes"

mPath = 'UNDEF'

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  if RunCommand.new('which', 'root', 'jython').run[0] == 0
  [
    v(cb("jython classes test") do
      mResult = RunCommand.new('source', 'root', File.join("~#{Command::ZIMBRAUSER}", '.bashrc'), '; printenv', 'JYTHONPATH').run
      next mResult if mResult[0] != 0
      mPath = mResult[1].split(/\n/).first
      mResult = RunCommand.new("env JYTHONPATH=#{mPath} jython", 'root', File.join(Command::ZIMBRAPATH, 'libexec', 'zmconfigd'), 'start').run
      mResult = RunCommand.new('ls', 'root', File.join(mPath, '*.class')).run
      next mResult if mResult[0] != 0
      mResult = RunCommand.new('chmod', 'root', '640', File.join(mPath, '*.class')).run
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
    v(RunCommand.new(File.join('libexec', 'zmconfigd'), Command::ZIMBRAUSER, 'start')) do |mcaller, data|
      mcaller.pass = data[0] != 0
    end,
    
    #run zmfixperms
    v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'libexec', 'zmfixperms'), 'root')) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
    v(RunCommand.new(File.join('libexec', 'zmconfigd'), Command::ZIMBRAUSER, 'start')) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end,
    
    v(cb("cleanup") do
      RunCommand.new('rm', 'root', '-rf', File.join(mPath, '*.class')).run #File.join(Command::ZIMBRAPATH, 'zimbramon', 'pylibs', '*.class')).run
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end
  ]
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
