#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2013 Zimbra
#
#

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
require "action/oslicense"
require 'model/deployment'
require 'action/zmlocalconfig'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Innotop basic test"

include Action
include Model

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  Deployment.getServersRunning('*').map do |x|
  [
    v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zminnotop'),
                     Command::ZIMBRAUSER,'--version', h = Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && (result = data[1][/Ver\s+(\S+)$/, 1]) == OSL::LegalApproved['innotop']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - innotop version' => {"IS" => result || data[1].chomp, "SB" => OSL::LegalApproved['innotop']}}
      end
    end,
      
    v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zminnotop'),
                     Command::ZIMBRAUSER,'--version', h)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && (result = data[1][/Ver\s+(\S+)$/, 1]) == OSL::LegalApproved['innotop']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - innotop version' => {"IS" => result || data[1].chomp, "SB" => OSL::LegalApproved['innotop']}}
      end
    end,
  ]
  end,
      
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zminnotop'),
                   Command::ZIMBRAUSER,'--help')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1]  =~ /^Usage: innotop <options> <innodb-status-file>\n/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'innotop help' => {"IS" => data[1], "SB" => "Usage: innotop <options> <innodb-status-file>..."}}
    end
  end,
    
  v(RunCommand.new(File.join(Command::ZIMBRAPATH, 'bin', 'zminnotop'),
                   Command::ZIMBRAUSER,'-S', File.join(Command::ZIMBRAPATH, 'data', 'tmp', 'mysql', 'mysql.sock'),
                   '-u', Command::ZIMBRAUSER,
                   '-p', ZMLocalconfig.new('-s', '-m', 'nokey', 'zimbra_mysql_password', h = Host.new(Deployment.getServersRunning('store').first)).run[1].chomp,
                   '-n', '--count', '2', h)) do |mcaller, data|
    mHeader = 'uptime\tmax_query_time\ttime_behind_master\tqps\tconnections\trun\tmiss_rate\tlocked_count\topen\tslave_running\tlongest_sql'
    mcaller.pass = data[0] == 0 && (lines = data[1].split(/\n/)).size == 3 &&
                   lines[0] =~ /^#{mHeader}$/
                   
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {h.to_s + ' - innotop noninteractive' => {"IS" => data[1], "SB" => "#{mHeader} followed by 2 lines"}}
        
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