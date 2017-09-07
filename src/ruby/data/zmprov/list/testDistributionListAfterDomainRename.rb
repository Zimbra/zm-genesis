#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 VMware
#
#  Test case for Bug 56768 (Distribution lists broken after a domain rename) 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "model"
require "action/block"
require "action/verify"
require "action/command"
require "action/runcommand"
require "action/zmprov"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Test case for Bug 56768 (Distribution lists broken after a domain rename)"

time = Time.now.to_i.to_s
test_domain = "test-domain-" + time + ".what.com"
test_domain_alias = "test-domain-alias-" + time + ".what.com"
test_dl = "test-dl" + "@" + test_domain
test_dl_alias = "test-dl" + "@" + test_domain_alias
test_dl_rename = "test-dl-rename" + "@" + test_domain_alias


#
# Setup
#
current.setup = [
 

]
#
# Execution
#
current.action = [
  v(ZMProv.new('cd', test_domain)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gad')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(test_domain)
  end, 
  
  v(ZMProv.new('cdl', test_dl)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
  end,  
 
  # create alias domain
  v(ZMProv.new('cad', test_domain_alias, test_domain)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,

  v(ZMProv.new('gd', test_domain_alias)) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?('objectClass: zimbraDomain') &&
                   data[1].include?('zimbraDomainName: '+ test_domain_alias) &&
                   data[1].include?('zimbraDomainType: alias')
  end,
  
  v(ZMProv.new('dd', test_domain_alias)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,  
 
  v(ZMProv.new('-l', 'rd', test_domain, test_domain_alias), 300) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,  

  v(ZMProv.new('gad')) do |mcaller, data|
    mcaller.pass = data[0] == 0 && data[1].include?(test_domain_alias)
  end,
  
  v(ZMProv.new('cad', test_domain, test_domain_alias)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end, 
  
  # Rename Distribution List after switching domain and domain alias 
  v(ZMProv.new('rdl', test_dl_alias, test_dl_rename)) do |mcaller, data|	
    mcaller.pass = data[0] == 0
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