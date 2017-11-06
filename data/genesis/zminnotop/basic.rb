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
#require "action/runcommand" 
require "action/verify"
require "action/oslicense"
require 'model/deployment'
#require 'action/zmlocalconfig'
require 'action/zminnotop'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zminnotop basic test"

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
  Model::Servers.getServersRunning('mailbox').map do |x|
  [
    v(ZMInnotop.new('--version', h = Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].include?(OSL::LegalApproved['innotop'])
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - innotop version' => {"IS" => result || data[1].chomp, "SB" => OSL::LegalApproved['innotop']}}
      end
    end,

    ['h'].map do |y|
      v(ZMInnotop.new('-' + y, h)) do |mcaller,data|
        mcaller.pass = data[0] == 0 && data[1].include?("Usage")
      end
    end,

    ([('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten - ['c', 'C', 'd', 'h', 'i', 'm', 'n', 'p', 'P', 'r', 's', 'S', 't', 'u', 'w']).map do |y|
      v(ZMInnotop.new('-' + y, '2>&1')) do |mcaller,data|
        mcaller.pass = data[0] != 0 && data[1] =~ /Unknown option:\s#{y}/
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - zminnotop unknown option' => {"IS"=>data[1] + data[2], "SB"=>'Unknown option: ' + x}}
        end
      end
    end,
    
    (['A'..'U'].map{|i| i.to_a}.flatten - ['E', 'F', 'G', 'H', 'J', 'N', 'P']).map do |y|
      v(ZMInnotop.new('-m ', y, '--count 1', '2>&1', h)) do |mcaller,data|
        mcaller.pass = data[0] == 0 && data[1].split(/\n/).first =~ /(\S+\t)+/
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - zminnotop -m option' => {"IS"=>data[1] + data[2], "SB"=>'\S\t...'}}
        end
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