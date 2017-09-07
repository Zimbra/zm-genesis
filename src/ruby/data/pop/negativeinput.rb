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
# Negative test cases for invalid input POP3


if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/simpleconnect"
require "action/block"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "POP3: invalid input"

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
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::POP)
      scon.send_str('')
    end ) do |mcaller, data|
      mcaller.pass = data.response.include?("ERR")
  end,
  
  # correct then empty
  v(cb("Command, Empty command") do
      result = Array.new
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::POP)
      result[0] = scon.send_str('noop').response
      result[1] = scon.send_str('').response
      result
    end) do |mcaller, data|
      mcaller.pass = data[0].include?('OK') &&
    data[1].include?('ERR')
  end,

  ## only space
  v(cb("Just space") do
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::POP)
      scon.send_str(' ')
    end) do |mcaller, data|
      mcaller.pass = data.response.include?('ERR')
  end,
  
  ## authenticate fake + authenticate null + authenticate space
  v(cb("Authenticate fake") do
      result = Array.new
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::POP)
      result[0] = scon.send_str('AUTH fake').response
      result[1] = scon.send_str('AUTH').response
      result[2] = scon.send_str('AUTH ').response
      result
    end) do |mcaller, data|
      mcaller.pass = data[0].include?('ERR') && 
        data[1].include?('ERR') && data[2].include?('ERR')
  end,
  
  ## user without user
  v(cb("Empty User") do
      result = Array.new
      scon = Action::SimpleConnect.new(Model::TARGETHOST, Model::Host::POP)
      result[0] = scon.send_str('USER').response
      result[1] = scon.send_str('USER ').response
      result
    end) do |mcaller, data|
      mcaller.pass = data[0].include?('ERR') && 
        data[1].include?('ERR')
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


