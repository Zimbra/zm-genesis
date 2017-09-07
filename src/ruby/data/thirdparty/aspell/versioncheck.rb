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
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby'))
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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Aspell version test"

include Action 


expected = '0.60.6.1'
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
  mCfg.getServersRunning('spell').map do |x|
  [
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH, 'common', 'bin','aspell'),
                       Command::ZIMBRAUSER,'--version')) do |mcaller, data|
        result = data[1][/International Ispell Version .* \(but really Aspell (.*)\)/, 1]
        mcaller.pass = data[0] == 0 && result == expected
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - aspell version' => {"IS"=>result, "SB"=>expected}}
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