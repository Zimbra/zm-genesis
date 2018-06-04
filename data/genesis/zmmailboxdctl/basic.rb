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
# Test zmmailboxdctl star, stop, restart
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
require "action/zmlocalconfig"
require 'rexml/document'


include Action
#include REXML

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmmailboxdctl"
lcKey = 'mailboxd_java_heap_size'
lcVal = 'UNKNOWN'
lcTestVal = ''

#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [

  v(ZMMailboxdctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && (data[1].include?("mailboxd started.") || data[1].include?("mailboxd already running."))
  end,

  v(ZMMailboxdctl.new('start')) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("mailboxd already running.")
  end,

  v(ZMMailboxdctl.new('status')) do |mcaller, data|
    mcaller.pass = (data[0] == 0)&& data[1].include?('mailboxd is running.')
  end,

# bug 50481

   v(RunCommand.new("cat", 'root', File.join(Command::ZIMBRAPATH, 'conf', 'localconfig.xml'))) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
      begin
        doc = REXML::Document.new data[1].slice(data[1].index('<?xml version'), data[1].index('</localconfig>') - data[1].index('<?xml version') + '</localconfig>'.length)
        lcVal = doc.get_elements("//key[@name='#{lcKey}']").first.elements['value'].text
        true
      rescue
        true
      end
  end,

  v(ZMLocalconfig.new('-e', "\"#{lcKey}=#{lcTestVal}\"")) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
                 
  cb("Resetting to original value") do
    if(lcVal != 'UNKNOWN')
      ZMLocalconfig.new('-e', "\"#{lcKey}=#{lcVal}\"").run
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
