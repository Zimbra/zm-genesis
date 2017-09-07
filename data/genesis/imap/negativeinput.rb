#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Vmware Zimbra
#
# Negative test cases for invalid input IMAP


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/simpleconnect"
require "net/imap"; require "action/imap" #Patch Net::IMAP library


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP: invalid input"

include Action

#
# Setup
#
current.setup = [
   
]

#
# Execution
#
current.action = [  
  # empty command
  v(cb("Empty command") do
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::IMAP)
      scon.send_str('')
    end ) do |mcaller, data|
      mcaller.pass =data.response.include?(Action::IMAP.badString)
  end,
  
  # correct then empty
  v(cb("Tag and command, Empty command") do
      result = Array.new
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::IMAP)
      result[0] = scon.send_str('newtag1 noop').response
      result[1] = scon.send_str('').response
      result
    end) do |mcaller, data|
      mcaller.pass = data[0].include?('newtag1') && data[0].include?('OK') &&
    data[1].include?(Action::IMAP.badString)
  end,
  
  # tag only
  v(cb("Tag only") do
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::IMAP)
      scon.send_str('newtag1')
    end) do |mcaller, data|
      mcaller.pass = data.response.include?(Action::IMAP.badString)
  end,
  
  # only tag and space
  v(cb("Tag and space") do
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::IMAP)
      scon.send_str('newtag1 ')
    end) do |mcaller, data|
      mcaller.pass = data.response.include?(Action::IMAP.badString)
  end,
  
  # authenticate fake + authenticate null + authenticate space
  v(cb("Authenticate fake") do
      result = Array.new
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::IMAP)
      result[0] = scon.send_str('tag1 authenticate fake').response
      result[1] = scon.send_str('tag2 authenticate').response
      result[2] = scon.send_str('tag3 authenticate ').response
      result
    end) do |mcaller, data|
      mcaller.pass = data[0].include?('NO') && data[0].include?('mechanism not supported') &&
        data[1].include?(Action::IMAP.badString) && data[2].include?(Action::IMAP.badString)
  end
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

