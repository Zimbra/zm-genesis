#!/usr/bin/ruby -w
#
# = action/append.rb
#
# Copyright (c) 2010 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP QRESYNC basic test
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "model" 
require "action/block"
require "action/decorator"
require "action/zmprov"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Append Size Test Bug 51902"

include Action 

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = d


#
# Setup
#
current.setup = [
                 
                ]

#
# Execution
#
#Net::IMAP.debug = true
current.action = [  
                  CreateAccount.new(testAccount.name,testAccount.password), 
                  cb("login") do
                    mimap.object = Net::IMAP.new(Model::TARGETHOST, *Model::TARGETHOST.imap)
                    mimap.login(testAccount.name, testAccount.password)
                  end,
                  # Simple append command
                  v(cb("Simple QRESYNC command") do
                    mimap.enable('QRESYNC')
                    mimap.method('send_command').call('SELECT INBOX (QRESYNC (1 11111))')
                  end) do |mcaller, data|
                    mcaller.pass = data.class == Net::IMAP::TaggedResponse &&
                      data['name'] == 'OK'
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
