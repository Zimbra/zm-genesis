#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# 
#


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "action/zmlocalconfig"
require "model"
require "#{mypath}/install/utils"


include Action
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmlocalconfig reload"

lcKey = 'soap_fault_include_stack_trace'
lcVal = 'UNKNOWN'
lcTestVal = 'false'
testAccount = Model::User.new("testLcReload#{Time.now.to_i.to_s}@#{Utils::zimbraDefaultDomain}", Model::DEFAULTPASSWORD)

#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  # backup soap_fault_include_stack_trace
  # set it true & relaod if necessary
  v(cb("include stack trace") do
    mResult = ZMLocal.new(lcKey).run
    lcVal = mResult if !mResult.include?('Warning')
    next [0, mResult] if lcVal == 'true'
    mResult = ZMLocalconfig.new('-e', "\"#{lcKey}=true\"").run
    mResult = ZMLocalconfig.new('--reload').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # create a test account
  v(CreateAccount.new(testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass =  (data[0] == 0) or (data[1] =~/ERROR: account.ACCOUNT_EXISTS/)
  end,
  
  # check stacktrace is included
  v(cb("include stack trace test", 600) do
    mResult = [0, nil]
    mResult = ZMProv.new('ga', testAccount.to_str, 'zimbraMailHost').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    myHost, myDomain = mResult[1].split("\n")[-1].split(/\s*:\s*/)[1].split('.', 2)
    host = Model::Host.new(myHost, Model::Domain.new(myDomain))
    mResult = RunCommand.new('zmmailbox', Command::ZIMBRAUSER,
                             '-z', '-d', '-m', testAccount.to_str, 
                             'gm', '100', host).run
  end) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].split("\n").select {|w| w =~ /\s+at com\.zimbra\./}.length > 1
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true   
      end
      if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      #TODO: match pattern only when node <Trace> exists
      mcaller.badones = {'include stack trace test' => {"IS" => data[1][/<Trace>.*<\/Trace>/m], "SB" => 'stack trace included'}}
    end
  end,

  v(cb("exclude stack trace") do
    mResult = ZMLocalconfig.new('-e', "\"#{lcKey}=false\"").run
    mResult = ZMLocalconfig.new('--reload').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(cb("exclude stack trace test", 600) do
    mResult = [0, nil]
    mResult = ZMProv.new('ga', testAccount.to_str, 'zimbraMailHost').run
    if(mResult[1] =~ /Data\s+:/)
      mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
    end
    myHost, myDomain = mResult[1].split("\n")[-1].split(/\s*:\s*/)[1].split('.', 2)
    host = Model::Host.new(myHost, Model::Domain.new(myDomain))
    mResult = RunCommandOn.new(host, 'zmmailbox', Command::ZIMBRAUSER,
                             '-z', '-d', '-m', testAccount.to_str, 
                             'gm', '100').run
  end) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].split("\n").select {|w| w =~ /\s+at com\.zimbra\./}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true   
      end
      if(data[1] =~ /Data\s+:/)
        data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      mcaller.badones = {'exclude stack trace test' => {"IS" => data[1][/<Trace>.*<\/Trace>/m], "SB" => 'no stack trace'}}
    end
  end,
  
  v(cb("local config restore") do
    if lcVal == 'UNKNOWN'
      ZMLocalconfig.new('-u', lcKey).run
    else
      ZMLocalconfig.new('-e', "\"#{lcKey}=#{lcVal}\"").run
    end
    mResult = ZMLocalconfig.new('--reload').run
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

]
#
# Tear Down
#

current.teardown = [
  DeleteAccount.new(testAccount.name),
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
