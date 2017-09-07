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
current.description = "Apache version test"

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
  mCfg.getServersRunning('apache').map do |x|
  [
    v(RunCommand.new(File.join(Command::ZIMBRACOMMON, 'bin', 'httpd'),
                     Command::ZIMBRAUSER,'-v', host = Model::Host.new(x))) do |mcaller, data|
      result = data[1][/Server version:\s+Apache\/(\S+)/, 1]
      #result = data[1]
      mcaller.pass = data[0] == 0 && result == OSL::LegalApproved['apache-httpd']
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - apache version' => {"IS" => result, "SB" => OSL::LegalApproved['apache-httpd']}}
      end
    end,
   
mCfg.getServersRunning('apr').map do |x|

    [

 v(RunCommand.new(File.join( 'strings', Command::ZIMBRACOMMON, 'lib'),
                     Command::ZIMBRAUSER,'libaprutil-1.so.0|grep 1.5', host = Model::Host.new(x))) do |mcaller, data|

        mcaller.pass = data[0] == 0 && result == OSL::LegalApproved["apache-apr-util"]
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' version ' => {"IS" => result, "SB" => OSL::LegalApproved["apache-apr-util"]}}
        end
      end
    ]
    end,

mCfg.getServersRunning('apu').map do |x|

    [

 v(RunCommand.new(File.join( 'strings', Command::ZIMBRACOMMON, 'lib'),
                     Command::ZIMBRAUSER,'libapr-1.so.0|grep 1.5', host = Model::Host.new(x))) do |mcaller, data|

        mcaller.pass = data[0] == 0 && result == OSL::LegalApproved["apache-apr"]
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' version ' => {"IS" => result, "SB" => OSL::LegalApproved["apache-apr"]}}
        end
      end
    ]
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
