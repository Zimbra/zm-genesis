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
require 'rexml/document'
include REXML
require "model/deployment"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "ZCS license test"

include Action 

limit = '-1'
expected = {'AccountsLimit' => limit,
            'ArchivingAccountsLimit' => limit,
            'AttachmentIndexingAccountsLimit' => limit,
            'EwsAccountsLimit' => limit,
            'ISyncAccountsLimit' => '50',
            'SMIMEAccountsLimit' => '-1',
            'TouchClientsAccountsLimit' => limit,
            'MAPIConnectorAccountsLimit' => limit,
            'MobileSyncAccountsLimit' => limit,
            'VoiceAccountsLimit' => limit,
            'ZSSAccountsLimit' => limit,
            'InstallType' => 'regular',
            'IssuedToEmail' => 'qa@zimbra.com',
            'IssuedToName' => 'zimbra qa',
            'ActivationId' => '\b[\da-f]{8}(-[\da-f]{4}){3}-[\da-f]{12}\b',
            'Fingerprint' => '\b[\da-f]{32}\b',
           }

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [
  Model::Deployment.getServersRunning('*').map do |x|
  [
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmlicense'),
                       Command::ZIMBRAUSER,'-p')) do |mcaller, data|
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:(.*?)\s*\}/m, 1]
      end     
      iResult = Hash[*iResult.split("\n").compact.select {|w| w =~ /\S+=\S+/}.collect{|y| y.split('=')}.flatten]
      iResult.default = 'Missing'
      expected.default = 'Missing'
      mcaller.pass = data[0] == 0 &&
                     !(limits = iResult.keys.select {|k| k =~ /.*Limit$/}).empty? &&
                     (errs = (expected.keys + limits).uniq.select {|k| iResult[k] !~ /#{Regexp.new(expected[k])}/}).empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"#{x} - license parameters" => Hash[*errs.collect{|w| [w, {"IS"=>"#{iResult[w]}", "SB"=>"#{expected[w]}"}]}.flatten]}
      end
    end,
   
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','zmlicense'),
                       Command::ZIMBRAUSER,'-c')) do |mcaller, data|
      iResult = data[1]
      if(iResult =~ /Data\s+:/)
        iResult = iResult[/Data\s+:(.*?)\s*\}/m, 1]
      end     
      iResult.strip!
      sb = "license is OK"
      mcaller.pass = data[0] == 0 && iResult =~ /#{sb}/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {"#{x} -license check" => {"IS"=>"#{iResult}", "SB"=>"#{sb}"}}
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