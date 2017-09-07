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
 
require "model" 
require "action/block"
require "action/runcommand" 
require "action/verify"
#require "action/zmcontrol" 

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Mysql scripts test"

include Action 


#
# Setup
#
current.setup = [
   
] 
#
# Execution
#

current.action = [       
  
  v(RunCommand.new("/bin/cat","root","/opt/zimbra/db/create_database.sql")) do |mcaller, data|
      result = data[1].split(/\n/).select {|w| w =~ /DROP DATABASE IF EXISTS/}
      #result = data[1]
      mcaller.pass = data[0] == 0 && result.length == 0
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {'drop database removed from /opt/zimbra/db/create_database.sql check' => {"IS"=>result.collect {|w| w.chomp!}[0], "SB"=>"Missing"}}
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