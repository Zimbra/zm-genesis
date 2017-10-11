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

#
# Test basic zmpython command
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
require "action/command"
require "action/verify"
require "action/zmpython"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmpython"

jython_version = '2.5.2'
#
# Setup
#
current.setup = [

]
#
# Execution
#
current.action = [

  v(ZMPython.new('-h')) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('usage: jython [option]')
  end,
  
  v(ZMPython.new('-V')) do |mcaller,data|
    result = data[1][/Jython\s(\d.*)+/,1]
	mcaller.pass = (data[0] == 0 && result == jython_version)
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'Jython version' => {"IS"=>result, "SB"=>jython_version}}
    end
  end,
  
  v(ZMPython.new('-c',"\"import tempfile;print tempfile.gettempdir()\"")) do |mcaller,data|
    mcaller.pass = data[0] == 0 && data[1].include?('/tmp')
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
