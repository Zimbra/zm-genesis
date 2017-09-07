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
# check nginx LD_RUN_PATH

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
require "action/buildparser"
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "nginx run path test"

include Action 

expected = Regexp.new(".*lib(sasl2|ssl|crypto)\..*")
extension = '.so'
cmd = 'ldd'

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(cb("nginx runpath test") do 
    if BuildParser.instance.targetBuildId =~ /MACOSX/i
      extension = '.dylib'
      cmd = 'otool -L'
    end
    mObject = ConfigParser.new()
    mResult = mObject.run
    servers = mObject.getServersRunning('proxy')
    if servers.empty?
      next([0, "nginx not installed, skipping"])
    end
    mObject = RunCommandOn.new(servers[0], cmd, Command::ZIMBRAUSER,
                               File.join(Command::ZIMBRAPATH,'common', 'sbin', "nginx"))
    mResult = mObject.run[1]
    if mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.select {|w| w =~ /#{Command::ZIMBRAPATH}/}.size == 3
      [0, mResult[/\s*#{expected}\s+.*/]]
    else
      if(mResult =~ /Data\s+:/)
        mResult = (mResult)[/Data\s+:\s+(.*?)\s*\}/m, 1]
      end
      [1, ["#{servers[0]}: ldd " + File.join(Command::ZIMBRAPATH,'common', 'sbin', "nginx"), 
           mResult.split(/\n/).select {|w| w =~ /\s*#{expected}\s+.*/}.select {|w| w !~ /#{Command::ZIMBRAPATH}/}, expected.source]]
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'nginx run path test' => {data[1][0] => {"IS"=>data[1][1], "SB"=>data[1][2]}}}
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