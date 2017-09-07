#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# bug 77677

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/command"
require "action/block"
require "action/zmprov"
require "action/verify"
require "action/runcommand"
require "action/zmlocalconfig"
require "action/zmstatldap"
require "action/zmcontrol"
require "model"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmstat-ldap in tls mode"

tls_mode = ZMLocalconfig.new('ldap_common_require_tls').run[1].match(/\d$/) 
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  if tls_mode == 0
    [
      ZMLocalconfig.new('-e', 'ldap_common_require_tls=1'),
      ZMControl.new('restart'),
    ]
  end,
  
  v(ZMStatldap.new()) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   data[1] =~ /Already running as pid \d+$/
  end,

]
#
# Tear Down
#

current.teardown = [
  if tls_mode == 0
    [
      ZMLocalconfig.new('-e', "ldap_common_require_tls=#{tls_mode}"),
      ZMControl.new('restart')
    ]
  end
]


if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance).run
end
