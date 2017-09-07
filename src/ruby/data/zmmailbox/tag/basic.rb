#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2011 VMWare
#
# zmmailbox tag basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/block"
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmmailbox tag Basic test"

 
include Action

name = 'zmmailboxtag'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)

usage = ['createTag\(ct\)\s+\[opts\]\s+\{tag-name\}',
         '-c\/--color <arg>\s+color',
         'deleteTag\(dt\)\s+\{tag-name\}',
         'getAllTags\(gat\)\s+\[opts\]',
         '-v\/--verbose\s+verbose output',
         'markTagRead\(mtr\)\s+\{tag-name\}',
         'modifyTagColor\(mtc\)\s+\{tag-name\} \{tag-color\}',
         'renameTag\(rt\)\s+\{tag-name\} \{new-tag-name\}'
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
  CreateAccount.new(testAccount.name,testAccount.password),
  v(ZMailAdmin.new('-m', testAccount.name, 'help', 'tag')) do |mcaller, data|
    mResult = ZMMail.outputOnly(data[1])
    mcaller.pass = data[0] == 0 && usage.select{|w| mResult !~ /#{w}/}.empty? &&
                   mResult.split(/\n/).select {|w| w !~ /(#{Regexp.compile(usage.join('|'))})/}.select {|w| w !~ /^\s*$/}.empty?
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'gat')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 && ZMMail.outputOnly(data[1]).empty?
  end,

  v(ZMailAdmin.new('-m', testAccount.name, 'ct', 'foo')) do |mcaller, data|  
    mcaller.pass = data[0] == 0 &&
                   !(mRes = ZMMail.outputOnly(data[1])).nil? &&
                   mRes =~ /\d+/
  end,
  
  v(ZMailAdmin.new('-m', testAccount.name, 'dt', 'foo')) do |mcaller, data|
    mcaller.pass = data[0] == 0 &&
                   ZMMail.outputOnly(data[1]).empty?
  end,

]
#
# Tear Down
#
current.teardown = [    
   DeleteAccount.new(testAccount.name)    
   
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end