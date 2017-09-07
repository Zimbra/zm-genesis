#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2013 VMware
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
require 'action/oslicense'
require "#{mypath}/install/configparser"
require "action/buildparser"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zeromq version test"

include Action 

(mCfg = ConfigParser.new).run

mArchitecture = BuildParser.instance.targetBuildId[/zcs_([^_]+(_64)?)_/, 1]


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

=begin
  current.action = [       
  
  mCfg.getServersRunning('mta').map do |x|
  [
    v(RunCommand.new('cat', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH, 'zeromq', 'lib', 'pkgconfig', 'libzmq.pc'),  '2>&1', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && (result = data[1][/Version: (\S+)/, 1]) == OSL::LegalApproved['zeromq']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - zeromq version' => {"IS" => result, "SB" => OSL::LegalApproved['zeromq']}}
      end
    end,
  ]
  end,
  
  (mCfg.getServersRunning('*') - mCfg.getServersRunning('mta')).map do |x|
  [
    v(RunCommand.new('cat', Command::ZIMBRAUSER, File.join(Command::ZIMBRAPATH, 'zeromq', 'lib', 'pkgconfig', 'libzmq.pc'),  '2>&1', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] != 0 && data[1] =~ /No such file or directory/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - zeromq version' => {"IS" => data[1], "SB" => 'No such file or directory'}}
      end
    end,
  ]
  end,
  
  ]
=end


current.action = [

mCfg.getServersRunning('*').map do |x|
[
v(cb("zeromq version") do
  if mArchitecture =~ /UBUNTU/
        mObject = RunCommand.new('dpkg -s zimbra-zeromq-lib',Command::ZIMBRAUSER, Model::Host.new(x))
        result = mObject.run



  else
        mObject =  RunCommand.new('yum info zimbra-zeromq-libs',Command::ZIMBRAUSER, Model::Host.new(x))
        result = mObject.run


  end
 end) do |mcaller, data|

     result = data[1][/\s(4.1..)/]
       mResult = result.strip
      mcaller.pass = data[0] == 0 && mResult == OSL::LegalApproved['zeromq']
       if(not mcaller.pass)
          class << mcaller
          attr :badones, true
          end
         mcaller.badones = {x + ' - ZeroMQ version' => {"IS" => mResult, "SB" => OSL::LegalApproved['zeromq']}}
         else
         end
        end
]
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

