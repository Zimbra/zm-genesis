#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2006 Zimbra
#
# zmprov basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"
require "action/block"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov Basic test"


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
  #Help

  ['-h', '--help'].map do |s|
     v(ZMProv.new(s)) do |mcaller, data|
        mcaller.pass = data[0] == 1 && data[1].include?('zmprov is used for provisioning. Try:')
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
  Engine::Simple.new(Model::TestCase.instance, true).run
end