#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$

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
require "action/zmprov"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "convertd lib check"

include Action 

libPath = File.join(Command::ZIMBRAPATH, 'convertd', 'lib', 'libmod_convert.so')
expectedLibs = %w{linux-vdso.so libm.so libdl.so libc.so ld-linux}

#
# Setup
#
current.setup = [
   
] 

#
# Execution
#

current.action = [
  v(cb("convertd lib check") do
    mResult = Action::RunCommand.new('/bin/ls', Command::ZIMBRAUSER, libPath).run
    if mResult[0] == 0
      mResult = Action::RunCommand.new('/usr/bin/ldd', Command::ZIMBRAUSER, libPath).run
      [0, mResult[1].gsub("\t", "").split(/\n/)]
    else
      [0, expectedLibs]
    end
    end) do |mcaller, data|
      mcaller.pass = expectedLibs.select{ |l| data[1].join() !~ /#{l}/}.empty?
      if not mcaller.pass
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {}
        mcaller.badones[libPath + ' check'] = { "IS" => data[1], "SB" => expectedLibs }
      end
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
