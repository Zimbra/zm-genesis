#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2010 VMWare
#
# zmprov dynamic list membership test

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
current.description = "Zmprov Dynamic List membership test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s
testAccountOne = Model::TARGETHOST.cUser(name+'1', Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)
testAccountThree = Model::TARGETHOST.cUser(name+'3', Model::DEFAULTPASSWORD)

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
  v(ZMProv.new('CreateAccount', testAccountTwo.name, testAccountTwo.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(ZMProv.new('CreateAccount', testAccountThree.name, testAccountThree.password)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  v(cb("modify dynamic list") do
    mResult = ZMProv.new('cddl',testAccountOne).run
    ZMProv.new('mdl',testAccountOne,
               'memberURL', "\"ldap:\/\/\/\?\?sub\?\(&\(zimbraMemberOf=#{mResult[1].chomp}\)\(uid=#{name}*\)\)\"",
               'zimbraIsACLGroup', 'FALSE').run
  end) do |mcaller, data| 
    mcaller.pass = data[0] != 0 &&
                   data[1] =~ /ERROR: service.INVALID_REQUEST .*cannot modify memberURL when zimbraIsACLGroup is TRUE/
  end,
  
  #Add members
  v(ZMProv.new('adlm', testAccountOne.name, testAccountTwo.name, testAccountThree.name)) do |mcaller, data|
    mcaller.pass = data[0] == 0
  end,
  
  # Get dynamic Distribution List
  v(ZMProv.new('gdl', testAccountOne)) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && 
    data[1].include?(testAccountTwo.name) &&
    data[1].include?(testAccountThree.name)
  end,

  #TODO:
=begin
  $ zmprov cd ddd.com
b470d568-eea1-4e8b-8e54-0cef4e8afe57
$ zmprov cddl dl@ddd.com
c7eaaf69-72ac-4a80-9ae0-8a1f093dbef3
$ zmprov dd ddd.com
ERROR: account.DOMAIN_NOT_EMPTY (domain not empty: ddd.com (remaining entries:
...))
$ zmprov ddl dl@ddd.com
$ zmprov dd ddd.com
ERROR: service.FAILURE (system failure: unable to purge domain:
b470d568-eea1-4e8b-8e54-0cef4e8afe57)
=end

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