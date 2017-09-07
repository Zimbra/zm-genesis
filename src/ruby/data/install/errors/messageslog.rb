#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare
# Check for errors in /var/log/messages

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
current.description = "message log errors detection test"

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
    v(cb("/var/log/messages errors detection test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', log = File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h = Model::Host.new(x)).run
      mResult[1] = mResult[1].split(/\n/)
      next mResult << log if mResult[0] != 0
      startTime = getStartTime(mResult[1].last, h) rescue DateTime.now
      mResult = RunCommand.new('/bin/cat', 'root', (log = File.join('/var', 'log', 'messages')), h).run
      next mResult << log if mResult[0] != 0
      mResult[1] = mResult[1].split(/\n/)
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = mResult[1].select do |w|
                     w =~ sel
                   end.select do |w|
                     w !~ rej
                   end.uniq.select  do |w|
                     month = DateTime.parse(w[/^(.*\d+(:\d+){2})/, 1] + " " + startTime.year().to_s).month
                     if month >= startTime.month || (month == 1 && startTime.month == 12)
                       DateTime.parse(w[/^(.*\d+(:\d+){2})/, 1] + " " + startTime.year().to_s) >= startTime
                     end
                   end
      mResult << log
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
        mcaller.badones = {x + ' - ' + data.last + ' errors check' => {"IS"=>data[1].slice(0, 10).push('...').join("\n"), "SB"=>"No error"}}
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
