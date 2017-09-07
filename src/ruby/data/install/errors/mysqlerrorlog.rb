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
current.description = "mysql log errors detection test"

include Action 

(mCfg = ConfigParser.new).run

#
# Setup
#
errors = ['\[ERROR\]']
excepts = ['^$']
(mCfg = ConfigParser.new).run

current.setup = [
   
] 
#
# Execution
#

current.action = [
  mCfg.getServersRunning('store').map do |x|
    v(cb("mysql errors detection test") do
      mResult = RunCommand.new("/bin/ls", 'root', '-rt1', log = File.join(Command::ZIMBRAPATH, 'log', 'zmsetup*.log'), h = Model::Host.new(x)).run
      mResult = RunCommand.new('/bin/cat', 'root', log, h).run
      mMessage = mResult[1].split(/\n/).select {|w| w =~ /Running as zimbra user: \/opt\/zimbra\/mysql\/bin\/mysql_upgrade/}.first
      mMessage = mResult[1].split(/\n/).first if mMessage.nil?
      sqlUpgradeTime = DateTime.parse(mMessage)
      log = File.join(Command::ZIMBRAPATH, 'log', 'mysql_error.log')
      mResult = RunCommand.new('/bin/cat', 'root', log, h).run
      next mResult << log if mResult[0] != 0
      #sanitize it
      ##ignore mysql performance table errors prior to running mysql_upgrade
      mResult[1] = mResult[1].split(/\n/)
      sel = /#{Regexp.compile(ErrorScanner::ERRORS.join('|'))}/
      rej = /#{Regexp.compile(ErrorScanner::EXCEPTS.join('|'))}/
      mResult[1] = mResult[1].select do |w|
                     w =~ sel
                   end.select do |w|
                     w !~ rej
                   end.select do |w|
                     DateTime.parse(w) >= sqlUpgradeTime ||
                     w !~ /please run mysql_upgrade to create it|Native table 'performance_schema'/
                   end
      mResult << log
      mResult << log
    end) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
      if(not mcaller.pass)
        class << mcaller
          attr :badones, true
        end
        mcaller.suppressDump("Suppressed log can be very large")
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
