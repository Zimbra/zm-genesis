#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2009 Yahoo
#

#
# Test basic zmgsautil command
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end
require "action/command"
require "action/zmprov"
require "action/verify"
require "action/zmgsautil"
require "model"


include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test zmgsautil"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
mailbox = Model::Servers.getServersRunning("mailbox").first.to_s
#
# Setup
#
current.setup = [


]
#
# Execution
#
current.action = [
  v(ZMGsautil.new('help')) do |mcaller, data|
    usage = [Regexp.escape('zmgsautil: {command}'),
             Regexp.escape('createAccount -a {account-name} -n {datasource-name} --domain {domain-name} -t zimbra|ldap -s {server} [-f {folder-name}] [-p {polling-interval}]'),
             Regexp.escape('addDataSource -a {account-name} -n {datasource-name} --domain {domain-name} -t zimbra|ldap [-f {folder-name}] [-p {polling-interval}]'),
             Regexp.escape('deleteAccount [-a {account-name} | -i {account-id}]'),
             Regexp.escape('trickleSync [-a {account-name} | -i {account-id}] [-d {datasource-id}] [-n {datasource-name}]'),
             Regexp.escape('fullSync [-a {account-name} | -i {account-id}] [-d {datasource-id}] [-n {datasource-name}]'),
             Regexp.escape('forceSync [-a {account-name} | -i {account-id}] [-d {datasource-id}] [-n {datasource-name}]'),
            ]
    mcaller.pass = data[0] != 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,

  v(ZMGsautil.new('createAccount', '-a', 'galsync@zimbra.com', '-n', 'zimbra',
                  '--domain', "domain.#{name}.com", '-s', mailbox, '-t', 'zimbra', 'p', '1d')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Error: no such domain: domain.#{name}.com") 
  end,
  
  v(ZMProv.new('cd', "domain.#{name}.com")) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMGsautil.new('createAccount', '-a', 'galsync@domain.%s.com'%name, '-n', 'zimbra',
                  '--domain', "domain.#{name}.com",
                  '-s', mailbox, '-t', 'zimbra', 'p', '1d')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^galsync@domain\.#{name}\.com\s+[\da-f\-]{36}$/
  end,
  
  v(ZMGsautil.new('createAccount', '-a', 'galsync1@domain.%s.com'%name, '-n', 'zimbra',
                  '--domain', "domain.#{name}.com",
                  '-s', mailbox, '-t', 'zimbra', 'p', '1d')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?("Error: email address already exists: galsync@domain.%s.com"%name) 
  end,
=begin
  v(ZMGsautil.new('createAccount', '-a', 'anytestaccount@%s'%mDomain, '-n', 'zimbra',
                  '--domain', mDomain, '-s', Model::TARGETHOST.to_s, '-t', 'zimbra')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('anytestaccount@%s'%mDomain) 
  end,

  v(ZMGsautil.new('deleteAccount', '-a', 'anytestaccount@%s'%mDomain)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
=end
  v(ZMGsautil.new('addDataSource', '-a', 'galsync@domain.%s.com'%name, '-n', 'test',
                  '--domain', 'domain.%s.com'%name, '-t', 'zimbra', '-f', 'gsfolder')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1] =~ /^galsync@domain\.#{name}\.com\s+[\da-f\-]{36}$/
  end,

  v(ZMGsautil.new('deleteAccount', '-a', 'galsync@domain.%s.com'%name)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
  end,
  
  v(ZMProv.new('dd', "domain.#{name}.com")) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].empty?
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
