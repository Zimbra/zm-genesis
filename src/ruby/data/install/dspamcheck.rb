#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

mypath = 'data'
if($0 =~ /data\/genesis/)
  mypath += '/genesis'
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "dspam version check"

include Action 

(mCfg = ConfigParser.new).run

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#


current.action = [
  mCfg.getServersRunning('mta').map do |x|
    v(RunCommand.new('cat', 'root', File.join(Command::ZIMBRAPATH, 'conf', 'dspam.conf'), Model::Host.new(x))) do |mcaller, data| 
      myarray = data[1].scan(/Home (.*)/)
      result = RunCommand.new('file', 'root', myarray.first).run
      mcaller.pass = result[1].include?('directory') 
    end
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