#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2012 VMWare
# Check for errors in /var/log/zimbra log

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
current.description = "zimbra log errors detection test"

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
  (pool = mCfg.getServersRunning('.*')).map do |x|
    v(cb("/var/log/zimbra.log errors detection test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', log = File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h = Model::Host.new(x)).run
      mResult[1] = mResult[1].split(/\n/)
      next mResult << log if mResult[0] != 0
      startTime = getStartTime(mResult[1].last, h) rescue DateTime.now
      mResult = Action::RunCommand.new('/bin/cat', 'root', log = '/var/log/zimbra.log', h).run
      mResult[1] = mResult[1].split(/\n/)
      next mResult << log if mResult[0] != 0
      #retain only errors after startTime (i.e upgrade only errors on upgrades)
      mResult[1] = mResult[1].select  do |w|
                     DateTime.parse(w[/^([^:]+\d+(:\d+){2})/, 1] + " " + startTime.year().to_s) >= startTime rescue true
                   end
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = mResult[1].select do |w|
                     w =~ sel
                   end.select do |w|
                     w !~ rej
                   end.collect {|w| w.strip}
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
  
  pool.map do |x|
    v(cb("/var/log/zimbra.log duplication detection test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', log = File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h = Model::Host.new(x)).run
      mResult[1] = mResult[1].split(/\n/)
      next mResult << log if mResult[0] != 0
      startTime = getStartTime(mResult[1].last, h) rescue DateTime.new
      mResult = Action::RunCommand.new('/bin/cat', 'root', log = '/var/log/zimbra.log', h).run
      mResult[1] = mResult[1].split(/\n/)
      next mResult << log if mResult[0] != 0
      #sanitize
      ignore = ['^\s+\S+',
                'zmmailboxdmgr.* assuming no other instance is running',
               ]
      ignore.push(['su: \(to zimbra\) root on\s',
                   'su: \(to root\) root on none',
                   'COMMAND=\/opt/zimbra\/libexec\/zmmailboxdmgr status',
                   'COMMAND=\/opt\/zimbra\/libexec\/zmmtastatus',
                   'slapd\[\d+\]: OTP unavailable because can\'t read\/write key database \/etc\/opiekeys: Permission denied']) if Model::TARGETHOST.architecture == 48
      rej = /#{Regexp.compile(ignore.flatten.join('|'))}/
      mResult[1] = mResult[1].select {|w| w !~ rej}
      #retain only errors after startTime (i.e upgrade only errors on upgrades)
      mResult[1] = mResult[1].select  do |w|
                     DateTime.parse(w[/^([^:]+\d+(:\d+){2})/, 1] + " " + startTime.year().to_s) >= startTime rescue true
                   end
      mResult << log
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].size - data[1].uniq.size <= ErrorScanner::DUPLICATE_THRESHOLD #may need to increase the limit after collecting statistics
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        duplicate = {}
        data[1].each  do |w|
          duplicate[w] = 0 if !duplicate.has_key?(w)
          duplicate[w] += 1
        end
        duplicate.delete_if {|k, v| v == 1}
        mcaller.suppressDump("Suppress dump, the result has #{data[1].size} lines") if data[1].size >= 100
        mcaller.badones = {x + ' - ' + data.last + ' duplicate messages check' => {"IS"=> "#{duplicate.keys.size} matches, #{duplicate.keys.sort.slice(0, 10).push('...').join("\n")}", "SB"=>"No error"}}
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
