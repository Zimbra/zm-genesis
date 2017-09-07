#!/usr/bin/ruby -w
#
# $File$ 
# $DateTime$
#
# $Revision$
# $Author$
# 
# 2007 Zimbra
#
# Search charset test
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
 
require "model"

require "action/block"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"


#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search Charset test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s

testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

message = <<EOF.gsub(/\n/, "\r\n")
Subject: hello
From: genesis@test.org
To: genesis@ruby-lang.org

Sequence message REPLACEME
EOF

 
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
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/charset"), 
  cb("Create 20 messages") { 
    1.upto(20) { |i|
      m.append("INBOX/charset",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  
  p(m.method('select'),"INBOX/charset"), 
  %w[US-ASCII UTF-8].map do |x| 
    v(p(m.method('search'),"*",x))do |mcaller, data|  
      mcaller.pass = (data.class == Array) && (data[0] == 20)
    end
  end,  
  
  v(p(m.method('uid_search'),"*","US-ASCII")) do |mcaller, data| 
    mcaller.pass = (data.class == Array) && (data[0].class == Fixnum)
  end,   
  
  p(m.method('delete'),"INBOX/charset"), 
  v(p(m.method('search'),"*","GARBAGE")) do |mcaller, data| 
    #some net/imap parsing exception work with it
    mcaller.pass = (data.class == Net::IMAP::NoResponseError) &&
      (data.message.include?('GARBAGE'))
  end,  
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