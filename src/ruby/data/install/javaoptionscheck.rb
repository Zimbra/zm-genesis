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
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/buildparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Java version test"

include Action 


expected = '-XX:ErrorFile'
#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmjava'),
                            Command::ZIMBRAUSER,'-version')) do |mcaller, data|
    result = data[1].split(/\n/).select {|w| w =~ /java version/}[0].chomp.split(/\"/)[-1]
    #result = data[1]
    res = []
    if result =~ /1\.6\.0/
      ['bin/zmjava', 'bin/zmjavaext', 'bin/zmlocalconfig', 'bin/zmrestoreoffline'].each do |cli|
        mObject = RunCommand.new('bash', Command::ZIMBRAUSER, '-x',
                                 File.join(Command::ZIMBRAPATH, cli),
                                 '--help 2>&1 | grep "/opt/zimbra/java/bin/java"')
        mResult = mObject.run
        iResult = mResult[1]
        #puts iResult
        if(iResult =~ /Data\s+:/)
          iResult = iResult[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
        end
        res << [cli, iResult[/^\+\s+(exec\s+){0,1}\/opt\/zimbra\/java\/bin\/java\s+(.*)$/, 2]]
      end
    end
    mcaller.pass = data[0] == 0 && res.select {|w| w[1] !~ /#{expected}/}.empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'java option' => {}}
      res.select {|w| w[1] !~ /#{expected}/}.each { |w| mcaller.badones['java option'][w[0]] = {"IS"=>w[1], "SB"=>".*#{expected}=.*"}}
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