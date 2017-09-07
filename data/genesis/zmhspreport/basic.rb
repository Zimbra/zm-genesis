#!/bin/env ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2010 Zimbra
#
#  Basic sanitycheck for zmhspreport
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

include Action
mResult = 0

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmhspreport"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [     
                  cb("Get number of domains") do
                    mResult = ZMProv.new('gad').run
                      if(mResult[1] =~ /Data\s+:/)
                        mResult[1] = mResult[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
                      end
                        mResult[1] = mResult[1].chomp.split.size
                  end,
                  ['','-d', '-v'].map do |x|
                    v(cb("Run zmhspreport") do 
                        RunCommand.new(File.join(Command::ZIMBRAPATH, 'libexec', 'zmhspreport'),
                                       Command::ZIMBRAUSER, x).run
                                       
                      end) do |mcaller, data|
                      mcaller.pass = data[0] == 0 && data[1].include?('Users') &&
                        data[1].include?("Total Domains:  %i" %mResult[1])
                        
                    end
                  end,
                   v(cb("Run zmhspreport help") do 
                        RunCommand.new(File.join(Command::ZIMBRAPATH, 'libexec', 'zmhspreport'),
                                       Command::ZIMBRAUSER, '-h').run
                      end) do |mcaller, data|
                      mcaller.pass = data[0] == 0 && data[1].include?('Usage')
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
