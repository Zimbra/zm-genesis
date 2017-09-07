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

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Mysql table test"

include Action 

(mCfg = ConfigParser.new).run
tablesToCheck = ['proc']
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
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','mysql'),
                       Command::ZIMBRAUSER,'-e', "\"show tables;\"",'mysql')) do |mcaller, data|
      skip = true
      result = []
      data[1].split(/\n/).each do |line|
        if line =~ /Tables_in_mysql/
          skip = false
        elsif !skip
          if line =~ /^\s*$/
            break
          else
            result << line.strip()
          end
        end
      end
      missing = tablesToCheck - result
      mcaller.pass = data[0] == 0 && missing.empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = Hash[*missing.collect {|w| [x + ' - mysql table ' + w, {"IS"=>"missing", "SB"=>w}]}.flatten]
      end
    end,
    
    v(RunCommandOn.new(x, File.join(Command::ZIMBRAPATH,'bin','mysql'),
                       Command::ZIMBRAUSER,'-e', "\"show tables;\"",'zimbra')) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].split(/\n/).select {|w| w =~ /jive/}.empty?
        if(not mcaller.pass)
          class << mcaller
            attr :badones, true
          end
          mcaller.badones = {x + ' - zimbra table(s)' => {"IS"=>data[1].split(/\n/).select {|w| w =~ /jive/}.join(','), "SB"=> 'Missing'}}
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