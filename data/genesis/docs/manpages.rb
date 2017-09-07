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

#mypath = 'data'
#if($0 =~ /data\/genesis/)
#  mypath += '/genesis'
#end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "man pages test"

include Action

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  ['pflogsumm',].map do |x|
    v(RunCommand.new("man", Command::ZIMBRAUSER, "#{x}", "| head -1")) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1]  =~ /#{x.upcase}\(\d+\)\s+User Contributed Perl Documentation/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"#{x} man page" => {"SB" => "exit code 0, #{x.upcase}...", "IS" => "exit code #{data[0]}, #{data[1].split(/\n/).join(', ')}"}}
      end
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