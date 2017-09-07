#!/usr/bin/ruby -w
#
# = action/list.rb
#
# Copyright (c) 2010 vmware
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP xlist test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Xlist test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)
testAccountTwo = Model::TARGETHOST.cUser(name+'2', Model::DEFAULTPASSWORD)

include Action

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
cflags =  [ 
             ['INBOX/one', [:Hasnochildren]],
             ['INBOX/two', [:Hasnochildren]],
             ['INBOX/three', [:Haschildren]]             
          ]
          

rflags =  [
            ['INBOX', [:Haschildren, :Inbox]],
            ['Junk', [:Noinferiors, :Spam]]
          ]
          
tflags = [['', [:Noselect]]]

trflags = [['INBOX/three', [:Haschildren]]]
trtrflags = [['INBOX/three/three', [:Hasnochildren]]]
otrtrflags = [["/home/#{testAccountTwo.name}/INBOX/three/three", [:Hasnochildren]]]


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
  
  XlistVerify.new(mimap, '', '*', cflags + rflags),
  ['*', 'INBOX/%', '**', '%/%', '*%', '%*', '*/%', '%/*'].map do |x|
    XlistVerify.new(mimap, '', x, cflags)
  end,   
  XlistVerify.new(mimap, '', '//', cflags, &nilproc),  
  XlistVerify.new(mimap, '', '%%', rflags), 
  XlistVerify.new(mimap, '', '', tflags),  
  XlistVerify.new(mimap, 'INBOX/three/', '*', trtrflags), 
  XlistVerify.new(mimap, 'three', '', tflags),  
  ['*', '%'].map do |x|
      XlistVerify.new(mimap, x, x, &nilproc)
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
  XlistVerify.new(mimap, 'HI/thre', "/home/#{testAccountTwo.name}/INBOX/*", otrtrflags), 
  
  p(mimap.method('delete'),"INBOX/three/three"),
  p(mimap.method('delete'),"INBOX/three"),
  p(mimap.method('delete'),"INBOX/two"),
  p(mimap.method('delete'),"INBOX/one")
]

#
# Tear Down
#
current.teardown = [     
  p(mimap.method('logout')),
  p(mimap.method('disconnect')),  
  Action::DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end
