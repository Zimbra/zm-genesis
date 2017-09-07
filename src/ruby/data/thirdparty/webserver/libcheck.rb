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
require "action/zmlocalconfig"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Webserver jars test"

include Action 

(mCfg = ConfigParser.new()).run

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
    v(RunCommand.new('ls', 'root', File.join(Command::ZIMBRAPATH, 'jetty','lib', 'jcl*-over-slf*.jar'), '2>&1', Model::Host.new(x))) do |mcaller, data|
      mcaller.pass = data[0] != 0 && data[1] =~ /No such file or directory/
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - Webserver jars test' => {"SB" => 'No such file or directory', 'IS:' => "exit code #{data[0]}, #{data[1].chomp.strip}"}}
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