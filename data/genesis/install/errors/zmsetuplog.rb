#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
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
require "#{mypath}/install/errorscanner"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmsetup log errors detection test"

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
  mCfg.getServersRunning('.*').map do |x|
    v(cb("Zmsetup errors detection test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1',
                               File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h = Model::Host.new(x)).run
      next [mResult[0], {mResult[1] => '1'}] if mResult[0] != 0
      log = mResult[1].split(/\n/).last
      mResult = RunCommand.new('/bin/cat', 'root', log, h).run
      next [mResult[0], {mResult[1] => '1'}] if mResult[0] != 0
      #sanitize it
      mResult[1] = mResult[1].gsub(/\n\t+/m, "\t").gsub(/\n(Caused by:\s+)/m, '\t\1').split(/\n/)
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = Hash[*mResult[1].select do |w|
                           w =~ sel
                         end.select do |w|
                           w !~ rej
                         end.collect do |w|
                           [w.chomp, 1]
                         end.flatten]
      mResult
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.badones = {x + ' - ' + data.last + ' errors check' => {}}
        data[1].keys.each_index do |i|
          mcaller.badones[x + ' - ' + data.last + ' errors check']["error #{i + 1}"] = {"IS"=>data[1].keys[i], "SB"=>"No error"}
        end
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
