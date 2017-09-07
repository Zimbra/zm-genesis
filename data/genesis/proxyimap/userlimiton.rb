#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# Turn on user log in limit
#
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/command"
require "action/block"
require "action/runcommand"
require "action/verify"
require 'yaml'

include Action
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Turn on user login limit for nginx proxy"



#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [  
 
  if(Model::TARGETHOST.proxy == true)
    [
      RunCommand.new('zmprov', Command::ZIMBRAUSER, 'mcf zimbraReverseProxyUserLoginLimit 1000'),
      RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'stop'),
      cb("Sleep a while") do 
         Kernel.sleep(10)
      end,
      v(RunCommand.new('zmproxyctl', Command::ZIMBRAUSER, 'start')) do |mcaller, data|
        mcaller.pass = data.first
      end
    ]
  end
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