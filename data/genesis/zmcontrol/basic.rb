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
# Test zmcontrol star, stop, reload
#


#if($0 == __FILE__)
#  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
#end


if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "action/zmcontrol"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmcontrol"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

 v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Running")
  end,

 v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Starting ") &&
                   data[1] !~ /failed/i &&
                   !data[1].include?("No such file or directory")
  end,

  v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Running") && !data[1].include?("Stopped")
  end,

  v(ZMControl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Stopping") && data[1] !~ /failed/i
  end,

  v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("Stopped")
  end,

  v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Starting ") && data[1] !~ /failed/i
  end,

  # allow time for all services to start
  v(cb("check status")do
    mResult = nil
    2.times do
      Kernel.sleep(5)
      mResult = ZMControl.new('status').run
      break if !mResult[1].include?("Stopped")
    end
    mResult
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Running") && !data[1].include?("Stopped")
  end,
    
  v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Starting ") && data[1] !~ /failed/i
  end,

  v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Running") && !data[1].include?("Stopped")
  end, 

  #Bug 46970
  v(ZMControl.new('-h')) do |mcaller, data|
  mcaller.pass = data[0] != 0 &&
                 data[1].include?("/opt/zimbra/bin/zmcontrol [-v -h -H <host>] command [args]") &&
                 data[1].include?("-v:	display version") &&
                 data[1].include?("-h:	print usage statement") &&
                 data[1].include?("-H:	Host name (localhost)") &&
                 data[1].include?("Command in:") &&
                 data[1].include?("restart                           Restart services") &&
                 data[1].include?("shutdown                             Stop services") &&
                 data[1].include?("start                               Start services") &&
                 data[1].include?("startup                             Start services") &&
                 data[1].include?("status                      Display service status") &&
                 data[1].include?("stop                                 Stop services")
  end,  

  v(ZMControl.new('restart'))do | mcaller,data|
   mcaller.pass = data[0] == 0 && data[1] !~ /failed/i
  end,
  #END Bug 46970

#  v(ZMControl.new('-H','Model::TARGETHOST')) do |mcaller, data|
#  mcaller.pass = (data[0] == 0) && data[1].include?("Command in:")
#  end,

  v(ZMControl.new('-v')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('Release') && data[1].include?('edition')
  end,

  v(ZMControl.new()) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("Command in:")
  end,

  v(ZMControl.new('shutdown')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Stopping")
  end,

  v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?("Stopped")
  end,

  v(ZMControl.new('startup')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Starting")
  end,

  v(ZMControl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Running")
  end,

  # Test case to verify Bug 33604
  v(ZMControl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i
  end,

  v(cb("check orphan processes") do
    mResult = RunCommand.new('/bin/ps','zimbra','-u','zimbra', '|', 'grep -i zmlogger').run
  end) do |mcaller, data|
    mcaller.pass = data[0] != 0 && !data[1].include?('zmlogger')
  end,
=begin
  v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = !data[1].include?('failed')
  end,
  
  # Test case to verify Bug 32945
  v(ZMControl.new('stop'))do | mcaller,data|
    mcaller.pass = !data[1].include?('failed')
  end,
=end
  v(cb("check remaining process", 240) do
    sleep(120)
    mResult = RunCommand.new('/bin/ps','root','-u','zimbra', '|', 'grep -i zimbra').run
  end) do |mcaller, data|
    mcaller.pass = data[0] != 0 && !data[1].include?('zimbra')
  end,

  v(ZMControl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] !~ /failed/i
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
