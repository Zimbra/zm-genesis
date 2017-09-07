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
require "action/oslicense"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "SpamAssassin version test"

include Action 


md5Cmd = (Model::TARGETHOST.architecture == 66 ? '/sbin/': '') + 'md5' +
         (Model::TARGETHOST.architecture == 9 || Model::TARGETHOST.architecture == 66 ? '' : 'sum')
         
extractor = 'SpamAssassin version\s+(\S+)'
(mCfg = ConfigParser.new).run
if !mCfg.getServersRunning('octopus').empty?
  expected = 'No such file or directory'
  extractor = "(#{expected})"
end

#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(RunCommand.new(File.join(Command::ZIMBRACOMMON,'bin','sa-learn'),
                   Command::ZIMBRAUSER,'-V')) do |mcaller, data|
    mcaller.pass = (result = data[1][/#{Regexp.new(extractor)}/, 1]) =~ /#{Regexp.escape(OSL::LegalApproved['spamassassin'])}\b/
    if(not mcaller.pass)
      class << mcaller
        attr :badones, true
      end
      mcaller.badones = {'SpamAssassin version' => {"IS" => result, "SB" => OSL::LegalApproved['spamassassin']}}
    end
  end,
  
  if mCfg.isPackageInstalled('zimbra-mta') && mCfg.getServersRunning('octopus').empty?
  [
    v(RunCommand.new('ls', Command::ZIMBRAUSER,
                     File.join('libexec','sa-learn'))) do |mcaller, data|
        mcaller.pass = data[0] != 0
        if(not mcaller.pass)
          if(data[1] =~ /Data\s+:/)
            data[1] = data[1][/Data\s+:\s+([^\s}].*?)$\s+\}/m, 1]
          end
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {'libexec/sa-learn == zimbramon/bin/sa-learn test' => {"IS"=>data[1], "SB"=>"same"}}
      end
    end,
  
    # to compute expected, run the command on //depot/zimbra/<BRANCH>/ZimbraServer/conf/spamassassin/...
    if RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, '.uninstall', 'packages', 'zimbra-core*')).run[1] =~ /GA/
    [
      v(RunCommand.new('ls', 'root',
                       File.join(Command::ZIMBRAPATH, 'data', 'spamassassin', 'rules', '*'),
                       '| sort -df',
                       '| xargs cat',
                       '|', md5Cmd)) do |mcaller, data|
          expected = 'cd0102373fa1350f67c55b312bd73c27'
          mcaller.pass = data[0] == 0 && data[1] =~ /^\s*#{expected}\s/
          if(not mcaller.pass)
            class << mcaller
              attr :badones, true
            end
            mcaller.badones = {'SpamAssassin rules checksum' => {"IS"=>data[1], "SB"=>expected}}
        end
      end
    ]
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
