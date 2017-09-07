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
require 'action/oslicense'
require "action/buildparser"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "heimdal version test"

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
  mCfg.getServersRunning('*').map do |x|
    v(cb("version check") do
      mRes = RunCommand.new(File.join(Command::ZIMBRAPATH,'heimdal/bin','hxtool'),
                            'root','--version', '2>&1', '| head -1', Model::Host.new(x)).run
      #[0,mRes[1].unpack("M*").first]
    end) do |mcaller, data|
      result = data[1][/hxtool\s+\(Heimdal\s+(\d+(\.\d+)+)\)/, 1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['heimdal'] #expected
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - heimdal version' => {"IS" => result, "SB" => OSL::LegalApproved['heimdal']}}
      end
    end
  end,
  
 ]

=end


current.action = [

mCfg.getServersRunning('*').map do |x|
[
v(cb("heimdal version") do
  if mArchitecture =~ /UBUNTU/
        mObject = RunCommand.new('dpkg -s zimbra-heimdal-lib',Command::ZIMBRAUSER, Model::Host.new(x)) # For Ubuntu machines
        result = mObject.run



  else
        mObject =  RunCommand.new('yum info zimbra-heimdal-libs',Command::ZIMBRAUSER, Model::Host.new(x))  # For RHEL machines
        result = mObject.run


  end
 end) do |mcaller, data|

     result = data[1][/\s1.5../]
       mResult = result.strip
      mcaller.pass = data[0] == 0 && mResult == OSL::LegalApproved['heimdal']
       if(not mcaller.pass)
          class << mcaller
          attr :badones, true
          end
         mcaller.badones = {x + ' - Heimdal version' => {"IS" => mResult, "SB" => OSL::LegalApproved['heimdal']}}
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
