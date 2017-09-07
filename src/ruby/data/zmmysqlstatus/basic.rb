#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2008 Yahoo
#
# Test zmmylogpasswd star, stop, reload
#


#if($0 == __FILE__)
#  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
#end


if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/command"
require "action/clean"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "model"
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmysqlstatus"

#
# Setup
#
current.setup = [
      RunCommand.new('zmmypasswd','--root','test123'),
      RunCommand.new('zmmypasswd','test123'),
      RunCommand.new('zmmylogpasswd','--root','test123'),
      RunCommand.new('zmmylogpasswd','test123'),

]
#
# Execution
#
current.action = [
  v(ZMMysqlstatus.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new('-h')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Displays this usage message") \
  end,

  v(ZMMysqlstatus.new('--help')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("Displays this usage message") \
  end,

  v(ZMMysqlstatus.new('-u', 'zimbra')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new('-u', 'root')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new('-u','testuser')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("ERROR") \
  end,

  v(ZMMysqlstatus.new('-u', 'zimbra', '-p','test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new('-u', 'root', '-p','test123')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new('-u', 'zimbra', '-p','wrongpassword')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("ERROR") \
  end,

  v(ZMMysqlstatus.new('-u', 'root', '-p','wrongpassword')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("ERROR") \
  end,

  v(ZMMysqlstatus.new('-d','wrongdb')) do |mcaller, data|
    mcaller.pass = (data[0] == 1) && data[1].include?("ERROR") \
  end,

  v(ZMMysqlstatus.new('-d','zimbra')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
  end,

  v(ZMMysqlstatus.new()) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("MySQL uptime:") \
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