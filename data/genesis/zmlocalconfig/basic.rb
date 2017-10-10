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
#
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
require "action/zmlocalconfig"
require "model"

include Action
include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmlocalconfig"

lcKey = 'zmconfigd_interval'
lcVal = 'UNKNOWN'
lcTestVal = '86400'

def lcXml(data, tagName)
  Document.new data[/(<#{tagName}.*\/(#{tagName})?>)/m, 1] rescue nil
end

#
# Setup
#
current.setup = [
]
#
# Execution
#
current.action = [

  v(RunCommand.new(File.join(Command::ZIMBRAPATH,'bin','zmlocalconfig'),Command::ZIMBRAUSER)) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?(Model::TARGETHOST)
  end,

  v(RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'localconfig.xml'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
      begin
        doc = lcXml(data[1], 'localconfig')
        lcVal = doc.get_elements("//key[@name='#{lcKey}']").first.elements['value'].text
        true
      rescue
        true
      end
  end,

  v(ZMLocalconfig.new('-e', "\"#{lcKey}=#{lcTestVal}\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'localconfig.xml'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   !(doc = lcXml(data[1], 'localconfig')).nil? &&
                   (keys = doc.get_elements("//key[@name='#{lcKey}']")).length == 1 &&
                   keys.first.elements['value'].text == lcTestVal
  end,
  
  v(ZMLocalconfig.new('-u', lcKey)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'localconfig.xml'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   !(doc = lcXml(data[1], 'localconfig')).nil? &&
                   doc.get_elements("//key[@name='#{lcKey}']").empty?
  end,

  v(cb("local config restore") do
    if lcVal == 'UNKNOWN'
      ZMLocalconfig.new('-u', lcKey).run
    else
      ZMLocalconfig.new('-e', "\"#{lcKey}=#{lcVal}\"").run
    end
  end) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMLocalconfig.new('-x')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /#{File.join(Command::ZIMBRAPATH, 'data', 'tmp')}/
  end,

  v(ZMProv.new('ms', Model::TARGETHOST.to_s, 'zimbraserviceEnabled', 'convertd')) do |mcaller, data|
    mcaller.pass = data[0] != 0 && data[1].include?('error: cannot replace multi-valued attr value unless -r is specified')
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