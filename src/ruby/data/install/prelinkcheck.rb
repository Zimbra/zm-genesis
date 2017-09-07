#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2009 Zimbra
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zimbra prelinks check"
expected = []


include Action
include Model


#
# Setup
#
current.setup = [
  
]
   
#
# Execution
#

current.action = [       
  # Test case to verify Bug 14567  
  v(RunCommand.new('/bin/grep', 'root', Command::ZIMBRAPATH, '/etc/prelink.conf').run)do |mcaller, data|
    mResult = RunCommand.new('/bin/cat', 'root', '/opt/zimbra/conf/zimbra.ld.conf').run
    iResult = mResult[1]  
    if(iResult =~ /Data\s+:/)
      iResult = (iResult)[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
      expected = iResult.split{"/\n+/"}
    end
    iResult = data[1]  
    if(iResult[1] =~ /Data\s+:/)
      iResult[1] = (iResult[1])[/Data\s+:\s+([^\s}].*?)\s*\}/m, 1]
    end
    mcaller.pass = (data[0] == 0) && (expected.select {|w| data[1].include?(w)}.empty?) 
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'prelink check' => {"IS"=>data[1], "SB"=>expected}}
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