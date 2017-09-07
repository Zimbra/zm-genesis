#!/usr/bin/ruby -w
#
# = action/rename.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP rename test cases
# 

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/zmprov"
require "action/proxy"
require "action/sendmail" 
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Rename test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s 
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
 
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
  CreateAccount.new(testAccount.name,testAccount.password),
  Action::SendMail.new(testAccount.name,'DummyMessageOne'),  
  proxy(mimap.method('login'),testAccount.name,testAccount.password),
  
  #Normal operation
  proxy(mimap.method('create'),"blurdybloop"),
  proxy(mimap.method('create'),"foo/bar"),  
  ListVerify.new(mimap, '', '*', ['blurdybloop','foo/bar'].map { |x| [x, [:Hasnochildren]] }), 
  RenameVerify.new(mimap, "blurdybloop","sarasoop"), 
  RenameVerify.new(mimap, "foo","zowie"),
  ListVerify.new(mimap, '', '*', ['sarasoop','zowie/bar'].map { |x| [x, [:Hasnochildren]] }) ,
  proxy(mimap.method('delete'),"sarasoop"),
  proxy(mimap.method('delete'),"zowie/bar"),
  proxy(mimap.method('delete'),"zowie"),
  
  #Special folders 
  RenameVerify.new(mimap, "INBOX","OUTBOX", &IMAP::RenameFailed),
  proxy(mimap.method('create'),"apple/orange/pear"), 
  proxy(mimap.method('create'),"FUNNY"),   
  RenameVerify.new(mimap,"apple/orange/pear","apple/orange/pear"),  
  ListVerify.new(mimap, '', '*', ['apple','apple/orange'].map { |x| [x, [:Haschildren]] }) ,
  ListVerify.new(mimap, '', '*', ['apple/orange/pear'].map { |x| [x, [:Hasnochildren]] }) ,  
 
  RenameVerify.new(mimap,"apple/orange/pear","Apple/orange/pear"),  
  ListVerify.new(mimap, '', '*', ['Apple','Apple/orange'].map { |x| [x, [:Haschildren]] }) ,
  ListVerify.new(mimap, '', '*', ['Apple/orange/pear'].map { |x| [x, [:Hasnochildren]] }) , 
  
  {"Sent" => "Cent", "Drafts" => "Draftw", "Trash" => "Crash",
    "Calendar" => "Daldenar", "Contacts" => "Dontacts", 
    'IDONTEXIST' => 'Ixist', '' => 'hmm' }.to_a.collect do |x|
      RenameVerify.new(mimap, x[0], x[1], &IMAP::RenameFailed)
  end,   
  
  proxy(mimap.method('create'),"Trash/garbage"), 
  ['Junk', 'Trash/garbage'].map do |x|
    RenameVerify.new(mimap, x, x)
  end,
  
  proxy(mimap.method('list'),"","*"),
  proxy(mimap.method('delete'),"Trash/carbage"),
  proxy(mimap.method('delete'),"Apple/orange/pear"),
  proxy(mimap.method('delete'),"Apple/orange"),
  proxy(mimap.method('delete'),"Apple"),
  
  #Complex tree operation
  proxy(mimap.method('create'),"one/two/three"), 
  proxy(mimap.method('create'),"one/two/four"),
  RenameVerify.new(mimap, "one/two/four", "one/four"),
  ListVerify.new(mimap, '', '*', [['one/two', [:Haschildren]]]), 
  ListVerify.new(mimap, '', '*', [['one/four', [:Hasnochildren]]]),   
   
  #proxy(mimap.method('rename'),"one","one/two/three/six"), 
  RenameVerify.new(mimap,'one', 'one/two/three/six', &IMAP::RenameFailed),
  ListVerify.new(mimap, '', '*', [['one', [:Haschildren]]]),  
#  proxy(mimap.method('delete'),"one/two/three"),
  proxy(mimap.method('delete'),"one/two/"),
  proxy(mimap.method('delete'),"one/four"),
  proxy(mimap.method('delete'),"one"),
  
  #Error case 
  {"error" => "error:error", "errorone" => 'error:error', 'errortwo' => "error#{19.chr}error",
    'errorthree' => "error#{20.chr}error" }.to_a.map do |x|
      [proxy(mimap.method('create'), x[0]), 
        RenameVerify.new(mimap, x[0], x[1], &IMAP::RenameFailed),
        proxy(mimap.method('delete'), x[0])]       
  end, 
]

#
# Tear Down
#
current.teardown = [     
  proxy(mimap.method('logout')),
  proxy(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]
if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end