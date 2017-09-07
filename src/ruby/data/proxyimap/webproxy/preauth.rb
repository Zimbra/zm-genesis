#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2011 Zimbra
#
# Basic test PreAuth authentication
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end

require "action/block"
require "action/zmprov"
require "action/verify"
require "action/preauth"
require "model"
require "action/wget"

include Action

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "Basic test for PreAuth authentication"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
testAccountFP = 'fp:' + testAccount.name

proto = getFrontWebProtocol()
unless %w(http https).include?(proto)
  proto = 'https'
end
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
  ZMProv.new('ma', testAccount.name, 'zimbraForeignPrincipal', testAccountFP),
  
  #positive test cases
  verifyWget("#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccount.name)),
  v(cb("PreAuth by ID") do
      testAccountId = ZMProv.new('ga', testAccount.name, 'zimbraId').run[1].match(/^zimbraId: (.*)$/)[1]
      urlString = "#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccountId, {:by => 'id'})
      RunCommand.new("wget", "root", "--no-proxy", '-P', '/tmp' ,'--no-check-certificate', '"' + urlString + '"').run
     end ) do |mcaller, data|
    mcaller.pass = (data[0] == 0) && data[1].include?("200 OK")
  end,
  
  verifyWget("#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccountFP, {:by => 'foreignPrincipal'})),
  
  # TODO - check expire and timestamp params
    
  # negative test cases
  # invalid token expiration time
  verifyWgetError("#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccount.name, {:expires => 'O'})),
  
  # invalid timestemp
  verifyWgetError("#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccount.name, {:timestamp => '1300000000000'})),
  
  # wrong PreAuthKey
  v(cb("wrong PreAuthKey") do
      result = []
      Action::PreAuth.preAuthKey = ((('a'..'f').to_a + (0..9).to_a)*3).sort_by {rand}.sort_by {rand}[0..63].join
      urlString = "#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccount.name)
      result = RunCommand.new("wget", "root", "--no-proxy", '-P', '/tmp' ,'--no-check-certificate', '"' + urlString + '"').run
      Action::PreAuth.reset
      result
     end ) do |mcaller, data|
    mcaller.pass = (data[0] != 0)
  end,
  
  # no PreAuth in URL
  verifyWgetError(("#{proto}://" + Model::TARGETHOST + Action::PreAuth.constructURL(testAccount.name)).match(/^.*(?=&preauth)/)[0]),
  
  # TODO: preauth for other account, preauth against other domain
  
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


