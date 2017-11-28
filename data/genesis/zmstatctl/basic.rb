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
# Test zmstatctl star, stop, reload
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

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
require "model"
require "action/zmamavisd"
require "#{mypath}/install/configparser"
require "action/buildparser"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmstatctl"

#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  v(ZMStatctl.new) do |mcaller, data|
    mcaller.pass = data[0] == 1 && data[1].include?("Usage: zmstatctl start|stop|restart|status|rotate")
  end,

  v(ZMStatctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
                   
  end,
  
  v(ZMStatctl.new('start')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
  end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
  end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 1
  end,

  v(ZMStatctl.new('start')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)
  end,
  
  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0               
  end,

  v(ZMStatctl.new('rotate')) do |mcaller, data|
    sleep(10)  #timing issue.. issue status call too fast
    mcaller.pass = data[0] == 0 
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0
   end,

  v(ZMStatctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('rotate')) do |mcaller, data|
    mcaller.pass = data[0] == 1
  end,

  v(ZMStatctl.new('start', '; sleep 10')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('status')) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMStatctl.new('restart')) do |mcaller, data|
    mcaller.pass = data[0] == 0 
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
