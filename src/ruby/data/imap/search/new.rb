#!/usr/bin/ruby -w
#
# = data/imap/new.rb
#
# Copyright (c) 2005 zimbra
#
# Written & maintained by Bill Hwang
#
# Documented by Bill Hwang
#
# IMAP SEARCH new test cases
#
if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/block"

require "action/decorator"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "action/zmprov"

require "net/imap"; require "action/imap" #Patch Net::IMAP library

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search New test"

name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
m1 = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action
m = d
m1 = d

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
                  cb("Imap connection initialization") do
                    m.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
                  end, 
                  
                  p(m, 'login', testAccount.name,testAccount.password),
                  p(m, 'create', "INBOX/new"), 
                  cb("Create 10 messages") {     
                    0.upto(9) { |i|      
                      sflags = ['DUMMY'] 
                      sflags = [:Seen]    
                      m.append("INBOX/new",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
                    }
                    "Done"
                  },
                  p(m, 'logout'),
                  cb("Imap connection initialization") do
                    m1.object =  Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)                                  
                  end, 
                  p(m1, 'login' ,testAccount.name,testAccount.password),
                  cb("Create 10 messages") {     
                    0.upto(9) { |i|      
                      sflags = ['DUMMY']
                      if(i%2 ==0) 
                        sflags = [:Seen]   
                      end
                      m1.append("INBOX/new",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
                    }
                    "Done"
                  },
                  #So we have 20 messages with different states
                  p(m1, 'select','INBOX/new'), 
                  {
                    %w[NEW] => (y = [12, 14, 16, 18, 20]),
                    %w[NOT NEW] => (z = (1..20).to_a - y),
                    %w[RECENT UNSEEN] => y
                  }.sort.map do |x|
                    SearchVerify.new(m1, x[0], x[1])
                  end,    
                  
                  v(p(m1, 'uid_search' ,'NOT NEW')) do |mcaller, data| 
                    mcaller.pass = (data.class == Array) &&
                      (data.size == 15) &&
                      data.inject(true) do |meta, obj|
                      meta && (obj.class == Fixnum)
                    end
                  end,
                  p(m1, 'delete','INBOX/new'), 
                  
                 ]

#
# Tear Down
#
current.teardown = [     
  p(m1, 'logout'),
  p(m1, 'disconnect'),  
  p(m, 'disconnect'),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run    
end
