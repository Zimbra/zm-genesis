#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2012 VMWare
#
# zmprov misc basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/zmprov"
require "action/verify"
require "action/block"
require "action/zmamavisd"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmprov flush cache test"


include Action

adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
zMailUrl = ZMProv.new('gs', '`zmhostname`', 'zimbraMailURL').run[1][/zimbraMailURL:\s*(\S+)/, 1]
allTypes = ZMProv.new('fc').run[1][/\{([^}<]*)/, 1].split('|').delete_if {|w| w =~ /</}
usage = [Regexp.escape('usage:  flushCache(fc) [-a] ' +
                       '{acl|locale|skin|uistrings|license|all|account|config|globalgrant|cos|domain|galgroup|' +
                       'group|mime|server|alwaysOnCluster|zimlet|<extension-cache-type>} ' +
                       '[name1|id1 [name2|id2...]]'),
         Regexp.escape('For general help, type : zmprov --help')
        ]
#
# Setup
#
current.setup = [

]

#
# Execution
#
current.action = [

  ['fc', 'FC', 'flushCache', 'flushcache'].map do |x|
    v(ZMProv.new(x)) do |mcaller, data|
      mcaller.pass = data[0] != 0 &&
                     data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
    end 
  end,
  
  ['fcx', 'xfc', 'fooflushCache', 'flushcacheblah'].map do |x|
    v(ZMProv.new(x)) do |mcaller, data|
      mcaller.pass = data[0] != 0 && 
                     data[1].strip.split(/\n/).first =~ /#{Regexp.escape('zmprov [args] [cmd] [cmd-args ...]')}/
    end 
  end,
  
  allTypes.map do |x|
    v(ZMProv.new('fc', x)) do |mcaller, data|
      mcaller.pass = data[0] == 0
    end
  end,
  
  v(ZMProv.new('fc', '-a')) do |mcaller, data|
    mcaller.pass = data[0] != 0 &&
                   data[1].split(/\n/).select {|w| w !~ /(#{usage.join('|')}|^$)/}.empty?
  end,
    
  #flushCache Flushing LDAP cache
  v(ZMProv.new('fc', 'account', adminAccount.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  # Test case for Bug 67836
  ZMProv.new('ms', Model::TARGETHOST, 'zimbraMailURL', "\"#{zMailUrl}s\""),
  
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
  
  ['skin', 'uistrings'].map do |x|
    v(ZMProv.new('flushCache', x, '2>&1')) do |mcaller, data|      
      mcaller.pass = data[0] == 0 && data[1].empty?
    end             
  end,

]
#
# Tear Down
#
current.teardown = [
  ZMProv.new('ms', Model::TARGETHOST, 'zimbraMailURL', "\"#{zMailUrl}\""),
  ZMMailboxdctl.new('restart'),
  ZMMailboxdctl.waitForMailboxd(),
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance
  Engine::Simple.new(Model::TestCase.instance, true).run
end