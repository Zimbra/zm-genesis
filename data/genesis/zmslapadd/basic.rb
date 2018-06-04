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
# zmslapadd basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"
require "action/verify"
require "action/runcommand"
require "action/zmcontrol"
require "action/zmslapcat"
require "action/configparser"
require "action/ldap"
require 'tmpdir'
require 'net/ldap'

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "zmslapadd Basic test"


include Action

mName = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
mDir = File.join(Command::ZIMBRAPATH, 'data', 'ldap', mName)
(mCfg = ConfigParser.new()).run

#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [
  ['', '-h', '--help'].map do |x|
    v(ZMSlapadd.new(x)) do |mcaller, data|
      usage = ['USAGE: Imports LDAP databases',
               'Main database: zmslapadd <FILE>',
               'Config database: zmslapadd -c <FILE>',
               'Accesslog database: zmslapadd -a <FILE>'
               ].collect {|w| Regexp.escape(w)}
      mcaller.pass = data[0] != 0 &&
                     data[1].split(/\n/).delete_if{|w| w =~ /^\s*$/}.select {|w| w !~ /#{usage.join('|')}/}.empty?
    end
  end,
  
  if mCfg.getServersRunning('ldap').size == 1
  [
    v(ZMSlapcat.new(mDir)) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
    
    v(RunCommandOnLdap.new('cp', 'root', File.join(mDir, 'ldap.bak'), File.join(mDir, 'ldap.bak.orig'))) do |mcaller, data|
      mcaller.pass = data[0] == 0 && data[1].empty?
    end,
  ]
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
