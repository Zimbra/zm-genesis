#!/usr/bin/ruby -w
#
# = data/imap/body.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH body test cases
# 
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"

require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search Body test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org
BCC: testmeREPLACEME@ruby-lang.org

Search body message REPLACEME
  Orange 
    Apple
      Pear.
Garbage.
me. "Quoted"
EOF
 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#
current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/body"),
  cb("Create 10 messages using append") {       
    1.upto(10) { |i|
      m.append("INBOX/body",message.gsub(/REPLACEME/,i.to_s),[:Deleted], Time.now)   
    }
    "Done"
  }, 
  
  p(m.method('select'),"INBOX/body"),    
  
  { "1" => [1] }.merge(
      %w[genesis hello Search SEARCH Orange Apple Garbage Garbage. 
        Quoted "Quoted"
      ].inject(Hash.new { |hash, key| hash[key] = (1..10).to_a }) do |mem, obj|   
        mem[obj]
        mem
      end #inject        
  ).sort.map do |x|
    SearchVerify.new(m, ["BODY", x[0]], x[1])
  end,    
      
  [
    ["BODY", "ear"], 
    ["BODY", "Pearl"], 
    ["BODY", "1", "BODY", "2"],
    ["BODY", "so#{1.chr}so"]
  ].map do |x|
    SearchVerify.new(m, x, &IMAP::EmptyArray)
  end, 
  
  {
    ["OR", "BODY", "1", "BODY", "2"] => [1, 2],
    ["NOT", "OR", "BODY", "1", "BODY", "2"] => (3..9).to_a,
    ["BODY", "1", "BODY", "1"] => [1]
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end,  
   
  p(m.method('send_command'),'SEARCH NOT (OR BODY 1 BODY 2)'),       
  v(p(m.method('uid_search'),["BODY", "1", "BODY", "1"])) do |mcaller, data|
    result = m.fetch(1, ["UID"])
    mcaller.pass = (result.class == Array) && (result[0].class == Net::IMAP::FetchData) &&
      (result[0].attr['UID'] == data[0])
  end,
  p(m.method('delete'),"INBOX/body"),   
]

#
# Tear Down
#
current.teardown = [     
  p(m.method('logout')),
  p(m.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end