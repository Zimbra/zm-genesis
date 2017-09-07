#!/bin/env ruby
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# IMAP SEARCH folder cases
# 
# Bug 2822

if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 

require "net/imap"; require "action/imap" #Patch Net::IMAP library
 
require "model"
require "action/block"

require "action/zmmailbox"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"

 
#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Search Folder Test"


name = 'isearch'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

m = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)
 
mFolder = "searchme"
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
   # Create Search folder on inbox with :seen flag
  ZMailAdmin.new('-m', testAccount.name, 'csf', '-t', 'message', '/'+mFolder, 'is:read'),
   
  p(m.method('login'),testAccount.name,testAccount.password), 
  cb("Create 10 messages") {     
    0.upto(9) { |i|      
      sflags = []
      if(i%2 ==0) 
        sflags = [:Seen]   
      end         
      m.append("INBOX",message.gsub(/REPLACEME/,i.to_s),sflags, Time.now) 
    }
    "Done"
  }, 
 
  p(m.method('select'),mFolder),  
  {
    %w[SEEN] => (y = (1..5).to_a),    
  }.sort.map do |x|
     SearchVerify.new(m, x[0], x[1])
  end, 
  v(cb("Status Check") do
    m.status(mFolder, ["MESSAGES", "RECENT","UNSEEN", "UIDVALIDITY"])
  end) do |mcaller, data|
    # test case is commented out until bug is moved from WONTFIX state
    mcaller.pass = true#(data['MESSAGES'] == 5) 
  end,
  
  # bug 63229 - select another folder after you've selected a search folder
  # might result in exception and closed connection
  SelectVerify.new(m, "INBOX")
   
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