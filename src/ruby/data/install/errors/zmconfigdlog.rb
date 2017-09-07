#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
# Check for errors in zmconfigd log


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
require "action/zmcontrol"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmconfigd log errors detection test"

include Action 

def getStartTime(log, host = Model::TARGETHOST)
  mResult = Action::RunCommand.new('/usr/bin/head', 'root', '-1', log, host).run
  DateTime.parse(mResult[1])
end

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
    v(cb("zmconfigd errors detection test") do
      h = Model::Host.new(x)
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', log = File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h).run
      next mResult << log if mResult[0] != 0
      startTime = getStartTime(mResult[1].split(/\n/).last, h) rescue DateTime.new
      mObject = RunCommand.new('/bin/cat', 'root', (log = File.join(Command::ZIMBRAPATH, 'log', 'zmconfigd.log')), h)
      mResult = mObject.run
      next mResult << log if mResult[0] != 0
      #sanitize it
      crt = startTime - 1/86400.0
      mResult[1] = mResult[1].split(/\n/).select  do |w|
                     (crt = w =~ /^\d+/ ? (DateTime.parse(w) rescue crt) : crt) >= startTime
                   end
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = Hash[*mResult[1].select do |w|
                           w =~ sel
                         end.select do |w|
                           w !~ rej
                         end.collect do |w|
                           [w.chomp, 1]
                         end.flatten]
      mResult << log
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty? ||
                     ZMControl.new('-v').run[1] !~ /Release\s+8\.[0-5].*/ && data[0] != 0 && data[1] + data[2] =~ /zmconfigd.log: No such file or directory/
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
