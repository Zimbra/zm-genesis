#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$


#
# 2010 Vmware Zimbra
#
# Test zmdbintegrityreport
#
#if($0 == __FILE__)
#  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
#end

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmdbintegrityreport"
require "action/zmsoap"
require "action/waitqueue"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmdbintegrityreport"
time = Time.now
datestring = time.strftime("%Y-%m-%d")
searchsubject = "Daily mail report for "+datestring
expected = ["Usage: /opt/zimbra/libexec/zmdbintegrityreport [-m] [-o] [-r] [-v] [-h]",
                "-m emails report to admin account, otherwise report is presented on stdout",
                "-o attempt auto optimization of tables", #Bug 103083
                "-r attempt auto repair of tables",
                "-v verbose output",
                "-h help"]
hasErrors = false
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMDbintegrityreport.new('--help')) do |mcaller,data|
    mcaller.pass = data[0] == 1 && data[1].split(/\n+/).sort == expected.sort
  end,
  
  v(ZMDbintegrityreport.new('-v')) do |mcaller,data|
	  mcaller.pass = (data[0] == 0 && (data[1].include?("No errors found") || data[1].include?("Database errors found")))
  end,
  
  v(ZMDbintegrityreport.new('-r')) do |mcaller,data|
    hasErrors = !data[1].empty?
	  mcaller.pass = data[0] == 0
  end,
  
  #Bug 50095 zmdbintegrityreport -m does not send mail to admin
  v(ZMDbintegrityreport.new('-m')) do |mcaller,data|
    mcaller.pass = data[0] == 0
  end,

  #Wait a bit for system to finish
  WaitQueue.new,
  
  v(ZMSoap.new('-z', '-m', 'admin@`zmhostname`', 'SearchRequest/query=in:inbox ../limit=1')) do |mcaller, data|
    eTime = Time.at(data[1][/\sd="(\d+)"\s/, 1].to_i/1000)
    mcaller.pass = data[0] == 0 &&
                   (hasErrors && data[1].include?('Database Integrity check report') && [-1,0].include?(time <=> eTime) ||
                    !hasErrors && !data[1].include?('Database Integrity check report'))
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
