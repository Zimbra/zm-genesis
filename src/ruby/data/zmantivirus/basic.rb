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
# Test zmantivirus star, stop, restart

#
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
require "action/zmamavisd"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmantivirusctl"

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMAntivirusctl.new('start')) do |mcaller, data|
     mcaller.pass = data[0] == 0 && data[1].include?("amavisd-mc is already running.") && 
                                   data[1].include?("amavisd is already running.") &&
                                   data[1].include?("clamd is already running.") &&
                                   data[1].include?("freshclam is already running.")
  end,
  # Bug 10692
  v(ZMAntivirusctl.new('status')) do |mcaller, data|
     mcaller.pass = data[0] == 0 && data[1].include?("antivirus is running")
  end,

  v(ZMAntivirusctl.new('stop')) do |mcaller, data|
     mcaller.pass = data[0] == 0 && data[1].include?("Stopping clamd...done.") && data[1].include?("Stopping freshclam...done.")
  end,

  v(ZMAntivirusctl.new('status')) do |mcaller, data|
     mcaller.pass = data[0] == 1 && data[1].include?("zmclamdctl is not running") && data[1].include?("zmfreshclamctl is not running")
  end,

  v(ZMAntivirusctl.new('start')) do |mcaller, data| 
    mcaller.pass = data[0] == 0 && data[1].include?("Starting clamd...done.") && data[1].include?("Starting freshclam...done.") 
  end,
  
  v(ZMAntivirusctl.new('status')) do |mcaller, data|
     mcaller.pass = data[0] == 0 && data[1].include?("antivirus is running")
  end,

  # restart/reload Bug 20504  - fixed
  v(ZMAntivirusctl.new('restart'), 240) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1]=~ /Stopping amavisd\.\.\. done\./i &&
                   data[1] =~ /Starting amavisd\.\.\.done\./i &&
                   data[1] =~ /Stopping clamd\.\.\.(done|clamd is not running)\./i &&
                   data[1] =~ /Starting clamd\.\.\.(done|clamd is already running)\./i &&
                   data[1] =~ /Stopping freshclam\.\.\.(done|freshclam is not running)\./i &&
                   data[1] =~ /Starting freshclam\.\.\.done\./i &&
                   data[1] =~ /Stopping amavisd\-mc\.\.\. done\./ &&
                   data[1] =~ /Starting amavisd\-mc\.\.\.done\./
  end,
    
  v(ZMAntivirusctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Stopping clamd...done")
  end,

  # Bug 32604
  v(ZMAntivirusctl.new('stop')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&  data[1].include?("Stopping clamd...clamd is not running.")
  end,

  # restart/reload Bug 20504 - fixed 
  # Bug 77444
  v(ZMAntivirusctl.new('reload'), 240) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1]=~ /Stopping amavisd\.\.\. done\./i &&
                   data[1] =~ /Starting amavisd\.\.\.done\./i &&
                   data[1] =~ /Stopping clamd\.\.\.(done|clamd is not running)\./i &&
                   data[1] =~ /Starting clamd\.\.\.(done|clamd is already running)\./i &&
                   data[1] =~ /Stopping freshclam\.\.\.freshclam is not running\./i &&
                   data[1] =~ /Starting freshclam\.\.\.done\./i &&
                   data[1] =~ /Stopping amavisd\-mc\.\.\. done\./ &&
                   data[1] =~ /Starting amavisd\-mc\.\.\.done\./
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