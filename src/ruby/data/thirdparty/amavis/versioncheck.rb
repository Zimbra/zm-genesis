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
require 'action/oslicense'
require "#{mypath}/install/configparser"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Amavis version test"

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
  [
    v(RunCommand.new(File.join(Command::ZIMBRACOMMON, 'sbin','amavisd'), Command::ZIMBRAUSER,
                     '-c', File.join(Command::ZIMBRAPATH, 'conf', 'amavisd.conf'), '-V', '2>&1', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = (result = data[1][/amavisd-new-(\S+)/, 1]) == OSL::LegalApproved['amavisd']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - amavisd version' => {"IS" => result, "SB" => OSL::LegalApproved['amavisd']}}
      end
    end,
  ]
  end,
  
  (mCfg.getServersRunning('*') - mCfg.getServersRunning('mta')).map do |x|
  [
    v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'amavisd', 'sbin','amavisd'), Command::ZIMBRAUSER,
                     '-c', File.join(Command::ZIMBRAPATH, 'conf', 'amavisd.conf'), '-V', '2>&1', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[1] =~ /No such file or directory/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - amavisd version' => {"IS" => data[1], "SB" => 'No such file or directory'}}
      end
    end,
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