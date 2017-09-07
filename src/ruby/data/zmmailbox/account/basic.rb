#!/bin/env ruby
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# zmmailbox admin basic test

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model" 
require "action/zmmailbox"
require "action/zmprov"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Zmmailbox Account Basic test"

 
include Action

name = 'zmmailbox'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s  
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
adminAccount = Model::TARGETHOST.cUser('admin', Model::DEFAULTPASSWORD)
 
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
  v(ZMailAdmin.new('-m', testAccount.name, 'cid', 'foo', 'zimbraPrefForwardReplyFormat', 'html')) do |mcaller, data|  
    mcaller.pass = %w{zimbraPrefIdentityName foo zimbraPrefForwardReplyFormat html}.all? do |word|
      data[1].include?(word)
    end       
  end, 
  #Duplicate create should trigger error
  v(ZMailAdmin.new('-m', testAccount.name, 'cid', 'foo', 'zimbraPrefForwardReplyFormat', 'same')) do |mcaller, data|  
    mcaller.pass = %w{IDENTITY_EXISTS}.all? do |word|
      data[1].include?(word)
    end       
  end, 
  
  v(ZMailAdmin.new('-m', testAccount.name, 'mid', 'foo', 'zimbraPrefForwardReplyFormat', 'html')) do |mcaller, data|  
    mcaller.pass = %w{ModifyIdentityResponse}.all? do |word|
      data[1].include?(word)
    end       
  end, 
  #repeat modification should work
  v(ZMailAdmin.new('-m', testAccount.name, 'mid', 'foo', 'zimbraPrefForwardReplyFormat', 'html')) do |mcaller, data|  
    mcaller.pass = %w{ModifyIdentityResponse}.all? do |word|
      data[1].include?(word)
    end       
  end, 
  
  v(ZMailAdmin.new('-m', testAccount.name, 'did', 'foo')) do |mcaller, data| 
    mcaller.pass = %w{DeleteIdentityResponse}.all? do |word|
      data[1].include?(word)
    end  
  end, 
  v(ZMailAdmin.new('-m', testAccount.name, 'mid', 'foo', 'zimbraPrefForwardReplyFormat', 'html')) do |mcaller, data|  
    mcaller.pass = %w{NO_SUCH_IDENTITY}.all? do |word|
      data[1].include?(word)
    end       
  end 
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