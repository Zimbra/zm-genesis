#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWare
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
require "action/oslicense"
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Mysql version test"

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
  mCfg.getServersRunning('store').map do |x|
  [
    v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'bin','mysql'),
                     Command::ZIMBRAUSER,'--version', Model::Host.new(x))) do |mcaller, data|
      result = data[1][/Distrib\s([^-]*).*/, 1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['mysql']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - mysql version' => {"IS" => result, "SB" => OSL::LegalApproved['mysql']}}
      end
    end,
      
    v(cb("Defaults file test") do 
      mMysqlDir = ZMLocalconfig.new('mysql_directory', '-x', h = Model::Host.new(x)).run[1][/mysql_directory\s*=\s*(\S+)$/, 1]    #Need to fix this line
      mMycnf = ZMLocalconfig.new('mysql_mycnf', h).run[1][/mysql_mycnf\s*=\s*(\S+)$/, 1]
      RunCommand.new(File.join(Command::ZIMBRACOMMON, 'bin', 'mysql'), 'root', '--help', h).run.push(mMycnf)
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 &&
                     data[1] =~ /Default options are read from the following files in the given order:\n#{data.last}\s+/
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