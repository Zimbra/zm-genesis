#!/usr/bin/ruby -w
#
# = data/imap/search/uid.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH uid test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/setenv"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search UID test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
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
   CreateAccount.new(testAccount.name,testAccount.password) 
]

#
# Execution
#  

 

current.action = [  
  p(m.method('login'),testAccount.name,testAccount.password),
  p(m.method('create'),"INBOX/uid"), 
  cb("Create 20 messages") { 
    1.upto(20) { |i|
      m.append("INBOX/uid",message.gsub(/REPLACEME/,i.to_s),[:Seen], Time.now) 
    }
    "Done"
  }, 
  p(m.method('select'),"INBOX/uid"),      
  cb('Get List of UIDS') do
    muid = m.fetch(1..20, ['UID']).sort { |a, b| a.seqno <=> b.seqno }.map do |x|
      x.attr['UID']      
    end
    Setenv.new(:tempuids,muid).run #store list of uids in enviorment heap
    muid
  end,
  
  {  "UID *" => [20],
     "UID *:*" => [20],
     "UID 2,4:7,9,12:*" => [2] + (4..7).to_a + [9] + (12..20).to_a,
     "UID 2 UID 2" => [2],
     "NOT UID 12:*" => (1..11).to_a,
     "OR UID 1 UID 20" => [1, 20],
     "UID 15" => [15],
     "UID 15" => [15]
  }.sort.map do |x|
    v(cb("UID Search [#{x[0]}]") do
        muid = Command.run_env[:tempuids] #fetch previously stored UID information
        auid =  x[0].gsub(/\d+/) { |s| muid[s.to_i-1].to_s } #translate ID to UID in the search string
        [m.uid_search(auid), m.search(auid)] #Get the UID
      end
    ) do |mcaller, data|
      muid = Command.run_env[:tempuids]  
      # make sure UID/ID returns matched  
      mcaller.pass = (data.inject(true) { |meta, obj| meta && (obj.class == Array) }) &&
        (data[0] == x[1].map { |y| muid[y-1]}) &&
        (data[1] == x[1])  
    end
  end, 
  p(m.method('delete'),"INBOX/uid") 
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