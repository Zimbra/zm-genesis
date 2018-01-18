#!/bin/env ruby
#
# = action/list.rb
#
# Copyright (c) 2014 Zimbra
#
#
# IMAP list test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "action/zmlocalconfig"
require "action/zmamavisd"
require "net/imap"; require "action/imap" #Patch Net::IMAP library


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP List special-use true test"

name = File.expand_path(__FILE__).sub(/.*?(data\/)(genesis\/)?(zm)?/, 'zm').sub('.rb', '').gsub(/\/|\(|\)/, '') + Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)

include Action

cflags =  [ 
             ['INBOX/one', [:Hasnochildren]],
             ['INBOX/two', [:Hasnochildren]],
             ['INBOX/three', [:Haschildren]]             
          ]
          
rflags =  [
            ['INBOX', [:Haschildren]],
            ['Junk', [:Noinferiors, :Junk]]
          ]
          
tflags = [['', [:Noselect]]]

trflags = [['INBOX/three', [:Haschildren]]]
trtrflags = [['INBOX/three/three', [:Hasnochildren]]]
otrtrflags = [["/home/#{testAccountTwo.name}/INBOX/three/three", [:Hasnochildren]]]

RunCommandOnMailbox.new('zmlocalconfig', Command::ZIMBRAUSER, '-e imap_force_special_use=TRUE').run  
#ZMLocalconfig.new('-e', 'imap_force_special_use=TRUE').run
ZMMailboxdctl.new('restart').run
Kernel.sleep(20) #wait for imap server to be running
mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

nilproc = proc { |mcaller, data| mcaller.pass = (data.class == NilClass) } 

#
# Setup
#
current.setup = [
  
]

#
# Execution
#
current.action = [  
  Action::CreateAccount.new(testAccount.name,testAccount.password),
  Action::CreateAccount.new(testAccountTwo.name,testAccount.password),
  p(mimap.method('login'),testAccount.name,testAccount.password),
  p(mimap.method('create'),"INBOX/one"),
  p(mimap.method('create'),"INBOX/two"),
  p(mimap.method('create'),"INBOX/three/three"), 
  
  ListVerify.new(mimap, '', '*', cflags + rflags),
  ['*', 'INBOX/%', '**', '%/%', '*%', '%*', '*/%', '%/*'].map do |x|
    ListVerify.new(mimap, '', x, cflags)
  end,   
  ListVerify.new(mimap, '', '//', cflags, &nilproc),  
  ListVerify.new(mimap, '', '%%', rflags), 
  ListVerify.new(mimap, '', '', tflags),  
  ListVerify.new(mimap, 'INBOX/three/', '*', trtrflags), 
  ListVerify.new(mimap, 'three', '', tflags),  
  ['*', '%'].map do |x|
      ListVerify.new(mimap, x, x, &nilproc)
  end,
  
  cb("Set ACL") {
    mimap2 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
    mimap2.login(testAccountTwo.name, testAccountTwo.password)
    mimap2.create("INBOX/three/three")
    mimap2.method('send_command').call("SETACL INBOX/three/three #{testAccount.name} lrswickxteda")
    mimap2.method('send_command').call("GETACL INBOX/three/three")
    mimap2.logout
    mimap2.disconnect
    mimap2
  },
  ListVerify.new(mimap, 'HI/thre', "/home/#{testAccountTwo.name}/INBOX/*", otrtrflags)
]

#
# Tear Down
#
current.teardown = [     
  p(mimap.method('logout')),
  p(mimap.method('disconnect')),
  RunCommandOnMailbox.new('zmlocalconfig', Command::ZIMBRAUSER, '-u imap_force_special_use'),
  ZMMailboxdctl.new('restart'),
  Action::DeleteAccount.new(testAccount.name),
  Action::DeleteAccount.new(testAccountTwo.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end