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
require "action/zmprov"
require "#{mypath}/install/utils"
require "#{mypath}/install/configparser"
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Cyrus-sasl basic test"

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
  
  v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'sbin','saslauthd'),
                   Command::ZIMBRAUSER,'-v')) do |mcaller, data|
    result = data[1][/saslauthd\s+(\d+\.\d+(\.\d+)?)/, 1]
    mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['cyrus-sasl-zimbra']
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'cyrus-sasl version' => {"IS" => result, "SB" => OSL::LegalApproved['cyrus-sasl-zimbra']}}
    end
  end,
  
  v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'sbin','saslauthd'),
                   Command::ZIMBRAUSER,'-v')) do |mcaller, data|
    expected = ['zimbra', 'kerberos5']
    reality = data[1][/authentication mechanisms:\s+(.*)/, 1].split(/\s/)
    mcaller.pass = data[0] == 0 && (expected - reality).empty?
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'cyrus-sasl authentication mechanisms' => {"IS"=>reality.sort.join(" "), "SB"=>expected.sort.join(" ")}}
    end
  end,
  
  mCfg.getServersRunning('mta').map do |x|
    v(cb("saslauthd test") do
      admin = nil
      Utils::getAdmins.select{|w| w.to_s =~ /\S+@\S+/}.each do |a|
        admin = a
        break if ZMProv.new('ga', a, 'zimbraIsAdminAccount').run[1] =~ /\s+/
      end
      mObject = RunCommandOn.new(x, File.join(Command::ZIMBRACOMMON, "sbin", 'testsaslauthd'),
                                 Command::ZIMBRAUSER,
                                 '-u', admin.to_s,
                                 '-p', Model::DEFAULTPASSWORD)
      mResult = mObject.run
      if(mResult[1] =~ /Data\s+:/)
        mResult[1] = (mResult[1])[/Data\s+:\s+([^\s}].*?)$\s*\}/m, 1]
      end
      mResult
    end) do |mcaller, data|
      success = '.*OK "Success."'
      mcaller.pass = data[0] == 0 && !data[1].split(/\n/).select {|w| w =~ /#{success}/}.empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'cyrus-sasl auth check' => {"IS"=>data[1], "SB"=>success}}
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
