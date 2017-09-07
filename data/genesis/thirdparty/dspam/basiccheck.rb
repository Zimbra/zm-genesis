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
require "#{mypath}/install/configparser"
require 'action/oslicense'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Dspam test"

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

=begin
  current.action = [       
  mCfg.getServersRunning('mta').map do |x|
  [
    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'dspam','bin', 'dspam'),
                              Command::ZIMBRAUSER,'--version', h = Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = (result = data[1][/DSPAM Anti-Spam Suite\s+(\S+)/, 1]) ==  OSL::LegalApproved['dspam']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Dspam version' => {"IS" => result, "SB" => OSL::LegalApproved['dspam']}}
      end
    end,
  
    v(RunCommand.new('cat', 'root', File.join(Command::ZIMBRAPATH, 'conf', 'dspam.conf'), h)) do |mcaller, data| 
      myarray = data[1].scan(/Home (.*)/)
      result = RunCommand.new('file', 'root', myarray.first).run
      mcaller.pass = result[1].include?('directory') 
    end,

    v(RunCommand.new(File.join(Command::ZIMBRAPATH,'dspam','bin', 'dspam_stats'),
                              Command::ZIMBRAUSER,'zimbra', "2>&1", h)) do |mcaller, data|
      mcaller.pass = data[0] == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        if(data[1] =~ /Data\s+:/)
          data[1] = (data[1])[/Data\s+:\s*([^\s}].*?)\s*\}/m, 1]
        end
        mcaller.badones = {'Dspam stats' => {"IS" => "exitCode=#{data[0]}, #{data[1].chomp}",
                                             "SB" => 'exitCode=0'}}
      end
    end
  ]
  end,
  
 ]

=end
    	

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