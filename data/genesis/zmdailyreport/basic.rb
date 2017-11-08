#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author: 


#
# 2010 Vmware Zimbra
#
# Test zmdailyreport
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
require "action/zmdailyreport"
require "action/zmsoap"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmdailyreport"
time = Time.now
datestring = time.strftime("%Y-%m-%d")
searchsubject = "Daily mail report for "+datestring
name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '')
testAccount = Model::TARGETHOST.cUser(name + time.to_i.to_s, Model::DEFAULTPASSWORD)
adminAccount = 'admin@' + Model::DOMAIN.to_s

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  v(ZMDailyreport.new('--help')) do |mcaller,data|
    usage = [Regexp.escape('Usage:'),
             Regexp.escape('zmdailyreport [options]'),
             Regexp.escape('Options:'),
             Regexp.escape('--mail') + '\s+' + Regexp.escape('Send report via email, default is stdout'),
             Regexp.escape('--help') + '\s+' + Regexp.escape('This help message'),
             Regexp.escape('--user') + '\s+' + Regexp.escape('User to deliver report to, default is localconfig smtp_destination')
            ]
    mcaller.pass = data[0] != 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,
  
  v(ZMDailyreport.new('--mail')) do |mcaller,data|
    mcaller.pass = data[0] == 0
  end,
  
  #Wait a bit for system to send mail 
  WaitQueue.new,    

  v(ZMSoap.new('-z', '-m', adminAccount, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse') &&
                   data[1].include?(searchsubject)
  end,
  
  #Create Account
  v(ZMProv.new('ca', testAccount.name, testAccount.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
    
  v(ZMDailyreport.new('--mail', '--user', testAccount.name)) do |mcaller,data|
    mcaller.pass = data[0] == 0
  end,
  
  #Wait a bit for system to send mail 
  WaitQueue.new,    

  v(ZMSoap.new('-z', '-m', testAccount.name, 'SearchRequest/query=in:inbox')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('SearchResponse') &&
                   data[1].include?(searchsubject)
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
